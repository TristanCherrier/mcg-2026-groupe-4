extends Node3D

const TERMINAL_SCENE := preload("res://Scenes/Actors/PuzzleTerminal.tscn")
const MONSTER_SCENE := preload("res://Scenes/Actors/MonsterRobot.tscn")
const FINISH_SCENE := preload("res://Scenes/Actors/FinishZone.tscn")
const CLASSROOM_SCENE := preload("res://classroom.tscn")

const GUIDE_COLOR := Color(0.2, 0.68, 0.9)
const EXIT_COLOR := Color(0.94, 0.47, 0.18)
const TOTAL_TERMINALS := 3
const ROOM_CENTER := Vector3(0.0, 0.0, -0.2)
const ROOM_FLOOR_SIZE := Vector3(13.2, 0.45, 14.2)
const ROOM_CEILING_SIZE := Vector3(13.2, 0.35, 14.2)
const ROOM_SIDE_WALL_SIZE := Vector3(0.35, 4.2, 14.2)
const ROOM_FRONT_WALL_SIZE := Vector3(13.2, 4.2, 0.35)
const ROOM_BACK_WALL_SIDE_SIZE := Vector3(3.9, 4.2, 0.35)
const ROOM_PLAYABLE_HEIGHT := 4.0
const SAFE_SPAWN_POSITION := Vector3(0.0, 0.25, 5.05)
const TERMINAL_A_POSITION := Vector3(-2.5, 0.6, 2.3)
const TERMINAL_B_POSITION := Vector3(2.5, 0.6, 0.6)
const TERMINAL_C_POSITION := Vector3(0.0, 0.6, -2.3)
const EXIT_WALKWAY_CENTER := Vector3(0.0, 0.0, -10.25)
const EXIT_WALKWAY_SIZE := Vector3(5.6, 0.24, 6.2)

var solved_count := 0
var exit_open := false
var spawn_transform := Transform3D.IDENTITY
var exit_door: StaticBody3D

@onready var player_root: Node3D = $Robot
@onready var player_ball: RigidBody3D = $Robot/ball_rb
@onready var hud: CanvasLayer = $HUD
@onready var architecture_root: Node3D = $Architecture
@onready var decor_root: Node3D = $Decor
@onready var gameplay_root: Node3D = $GameplayNodes
@onready var npc_root: Node3D = $NPCs
@onready var light_root: Node3D = $AccentLights


func _ready() -> void:
	GameState.enter_level("Niveau 1 - Salle de TP", scene_file_path)
	GameState.set_next_level("res://Scenes/Levels/Level2.tscn")
	GameState.set_objective(_build_progress_objective())
	GameState.set_help("Robot : ZQSD pour rouler, souris pour regarder, E pour interagir, V pour changer de vue.")
	GameState.set_integrity(100.0)
	GameState.set_energy(100.0)
	hud.configure("Niveau 1 - Salle de TP", false, false)
	player_ball.fell.connect(_on_player_fell)
	_build_level()
	spawn_transform = Transform3D(Basis.IDENTITY.rotated(Vector3.UP, PI), SAFE_SPAWN_POSITION)
	player_ball.respawn_at(spawn_transform)
	GameState.push_message("Cherchez les 3 bornes a ecran bleu, appuyez sur E, puis sortez par la porte orange.", 4.0)


func _process(delta: float) -> void:
	if exit_open and is_instance_valid(exit_door):
		exit_door.position.y = lerpf(exit_door.position.y, 4.8, delta * 1.8)


func _build_level() -> void:
	var classroom := CLASSROOM_SCENE.instantiate()
	architecture_root.add_child(classroom)
	_build_playable_shell()
	_build_exit_walkway()

	_make_guide_strip(Vector3(0, 0.03, 5.25), Vector3(3.2, 0.06, 0.22), GUIDE_COLOR)
	_make_guide_strip(Vector3(-1.25, 0.03, 3.75), Vector3(2.7, 0.06, 0.22), GUIDE_COLOR)
	_make_guide_strip(Vector3(1.25, 0.03, 2.15), Vector3(2.7, 0.06, 0.22), GUIDE_COLOR)
	_make_guide_strip(Vector3(0.0, 0.03, -0.85), Vector3(2.9, 0.06, 0.22), GUIDE_COLOR)
	_make_guide_strip(Vector3(0, 0.03, -5.7), Vector3(6.1, 0.06, 0.22), EXIT_COLOR)

	exit_door = _make_blocker(Vector3(0, 1.2, -6.2), Vector3(4.9, 2.4, 0.24), EXIT_COLOR, "ExitDoor")

	var friendly := MONSTER_SCENE.instantiate()
	friendly.friendly = true
	friendly.patrol_axis = Vector3(1, 0, 0)
	friendly.patrol_distance = 0.7
	friendly.patrol_speed = 1.0
	friendly.position = Vector3(5.25, 0.0, 5.15)
	npc_root.add_child(friendly)

	var scary_left := MONSTER_SCENE.instantiate()
	scary_left.patrol_axis = Vector3(1, 0, 0)
	scary_left.patrol_distance = 0.4
	scary_left.position = Vector3(-2.2, 0.0, -5.0)
	npc_root.add_child(scary_left)

	var scary_right := MONSTER_SCENE.instantiate()
	scary_right.patrol_axis = Vector3(-1, 0, 0)
	scary_right.patrol_distance = 0.4
	scary_right.position = Vector3(2.2, 0.0, -5.0)
	npc_root.add_child(scary_right)

	var terminal_a := _spawn_terminal(
		TERMINAL_A_POSITION,
		"Sequence energetique : 2, 4, 8, 16, ... quel nombre complete la suite ?",
		["24", "32", "18"],
		1,
		"Indice : la machine double sa puissance a chaque etape."
	)
	var terminal_b := _spawn_terminal(
		TERMINAL_B_POSITION,
		"Quel symbole chimique correspond au sodium utilise dans certains capteurs ?",
		["So", "Sn", "Na"],
		2,
		"Indice : pensez au tableau periodique."
	)
	var terminal_c := _spawn_terminal(
		TERMINAL_C_POSITION,
		"Pour reactiver le generateur, quel outil mesure la tension d'un circuit ?",
		["Le voltmetre", "Le barometre", "Le microscope"],
		0,
		"Indice : la reponse est liee a l'electricite."
	)
	terminal_a.solved_terminal.connect(_on_terminal_solved)
	terminal_b.solved_terminal.connect(_on_terminal_solved)
	terminal_c.solved_terminal.connect(_on_terminal_solved)
	_make_terminal_station(TERMINAL_A_POSITION, GUIDE_COLOR)
	_make_terminal_station(TERMINAL_B_POSITION, GUIDE_COLOR)
	_make_terminal_station(TERMINAL_C_POSITION, GUIDE_COLOR)
	_make_terminal_marker(TERMINAL_A_POSITION + Vector3(0.0, 0.3, 0.0), GUIDE_COLOR)
	_make_terminal_marker(TERMINAL_B_POSITION + Vector3(0.0, 0.3, 0.0), GUIDE_COLOR)
	_make_terminal_marker(TERMINAL_C_POSITION + Vector3(0.0, 0.3, 0.0), GUIDE_COLOR)

	var finish := FINISH_SCENE.instantiate()
	finish.position = Vector3(0, 0.12, -12.45)
	finish.target_group = "foot_player"
	finish.finish_entered.connect(_on_finish_entered)
	gameplay_root.add_child(finish)

	for light_data in [
		{"pos": Vector3(-4.8, 3.8, 5.1), "color": Color(0.75, 0.9, 1.0), "energy": 0.55},
		{"pos": Vector3(0.0, 3.8, 5.1), "color": Color(0.75, 0.9, 1.0), "energy": 0.55},
		{"pos": Vector3(4.8, 3.8, 5.1), "color": Color(0.75, 0.9, 1.0), "energy": 0.55},
		{"pos": TERMINAL_A_POSITION + Vector3(0.0, 1.4, 0.0), "color": Color(0.25, 0.75, 1.0), "energy": 0.45},
		{"pos": TERMINAL_B_POSITION + Vector3(0.0, 1.4, 0.0), "color": Color(0.98, 0.54, 0.24), "energy": 0.45},
		{"pos": TERMINAL_C_POSITION + Vector3(0.0, 1.4, 0.0), "color": Color(0.26, 0.85, 0.52), "energy": 0.45},
		{"pos": Vector3(0.0, 2.4, -5.9), "color": Color(0.98, 0.54, 0.24), "energy": 0.65}
	]:
		_make_light(light_data.pos, light_data.color, light_data.energy, 4.8)


func _spawn_terminal(position: Vector3, question: String, answers: Array[String], correct_index: int, hint: String) -> Area3D:
	var terminal := TERMINAL_SCENE.instantiate()
	terminal.position = position
	terminal.question = question
	terminal.answers = answers
	terminal.correct_index = correct_index
	terminal.objective_hint = hint
	gameplay_root.add_child(terminal)
	return terminal


func _on_terminal_solved(_terminal: Area3D) -> void:
	solved_count += 1
	if solved_count < TOTAL_TERMINALS:
		GameState.set_objective(_build_progress_objective())
		GameState.push_message("Terminal resolu : %d / %d." % [solved_count, TOTAL_TERMINALS], 2.0)
	else:
		exit_open = true
		GameState.set_objective("Les trois systemes sont reactives. Rejoignez maintenant le sas d'evacuation.")
		GameState.push_message("Tous les systemes sont en ligne : la sortie s'ouvre.", 3.0)


func _on_finish_entered(_body: Node) -> void:
	if solved_count >= TOTAL_TERMINALS:
		GameState.complete_level()
	else:
		GameState.push_message("Sortie verrouillee : %d / %d terminaux resolus." % [solved_count, TOTAL_TERMINALS], 2.5)


func _on_player_fell() -> void:
	GameState.apply_fall_penalty()
	GameState.push_message("Repositionnement dans la salle de TP.", 1.5)
	player_ball.respawn_at(spawn_transform)


func _make_guide_strip(position: Vector3, size: Vector3, color: Color) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	mesh.material_override = material
	mesh.position = position
	decor_root.add_child(mesh)


func _make_terminal_marker(position: Vector3, color: Color) -> void:
	var beam := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.14
	cylinder.bottom_radius = 0.14
	cylinder.height = 1.45
	beam.mesh = cylinder
	var beam_material := StandardMaterial3D.new()
	beam_material.albedo_color = Color(color.r, color.g, color.b, 0.28)
	beam_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	beam_material.emission_enabled = true
	beam_material.emission = color
	beam.material_override = beam_material
	beam.position = position + Vector3(0.0, 0.72, 0.0)
	decor_root.add_child(beam)

	var cap := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.22
	sphere.height = 0.44
	cap.mesh = sphere
	var cap_material := StandardMaterial3D.new()
	cap_material.albedo_color = color
	cap_material.emission_enabled = true
	cap_material.emission = color
	cap.material_override = cap_material
	cap.position = position + Vector3(0.0, 1.55, 0.0)
	decor_root.add_child(cap)

	var light := OmniLight3D.new()
	light.position = position + Vector3(0.0, 1.2, 0.0)
	light.light_color = color
	light.light_energy = 0.65
	light.omni_range = 3.6
	light_root.add_child(light)


func _make_terminal_station(position: Vector3, color: Color) -> void:
	_make_guide_strip(Vector3(position.x, 0.03, position.z), Vector3(1.25, 0.06, 1.25), color)
	var ring := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.62
	cylinder.bottom_radius = 0.62
	cylinder.height = 0.08
	ring.mesh = cylinder
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(color.r, color.g, color.b, 0.3)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.emission_enabled = true
	material.emission = color
	ring.material_override = material
	ring.position = Vector3(position.x, 0.08, position.z)
	decor_root.add_child(ring)


func _build_progress_objective() -> String:
	return "Resolvez les 3 terminaux scientifiques (%d / %d), puis sortez par la porte orange vers l'exterieur." % [solved_count, TOTAL_TERMINALS]


func _build_playable_shell() -> void:
	_make_collision_box(
		ROOM_FLOOR_SIZE,
		ROOM_CENTER + Vector3(0.0, -ROOM_FLOOR_SIZE.y * 0.5, 0.0),
		"RoomFloor"
	)
	_make_collision_box(
		ROOM_CEILING_SIZE,
		ROOM_CENTER + Vector3(0.0, ROOM_PLAYABLE_HEIGHT + ROOM_CEILING_SIZE.y * 0.5, 0.0),
		"RoomCeiling"
	)
	_make_collision_box(
		ROOM_SIDE_WALL_SIZE,
		ROOM_CENTER + Vector3(-ROOM_FLOOR_SIZE.x * 0.5 + ROOM_SIDE_WALL_SIZE.x * 0.5, ROOM_PLAYABLE_HEIGHT * 0.5, 0.0),
		"WallLeft"
	)
	_make_collision_box(
		ROOM_SIDE_WALL_SIZE,
		ROOM_CENTER + Vector3(ROOM_FLOOR_SIZE.x * 0.5 - ROOM_SIDE_WALL_SIZE.x * 0.5, ROOM_PLAYABLE_HEIGHT * 0.5, 0.0),
		"WallRight"
	)
	_make_collision_box(
		ROOM_FRONT_WALL_SIZE,
		ROOM_CENTER + Vector3(0.0, ROOM_PLAYABLE_HEIGHT * 0.5, ROOM_FLOOR_SIZE.z * 0.5 - ROOM_FRONT_WALL_SIZE.z * 0.5),
		"WallFront"
	)
	_make_collision_box(
		ROOM_BACK_WALL_SIDE_SIZE,
		ROOM_CENTER + Vector3(-4.6, ROOM_PLAYABLE_HEIGHT * 0.5, -ROOM_FLOOR_SIZE.z * 0.5 + ROOM_BACK_WALL_SIDE_SIZE.z * 0.5),
		"WallBackLeft"
	)
	_make_collision_box(
		ROOM_BACK_WALL_SIDE_SIZE,
		ROOM_CENTER + Vector3(4.6, ROOM_PLAYABLE_HEIGHT * 0.5, -ROOM_FLOOR_SIZE.z * 0.5 + ROOM_BACK_WALL_SIDE_SIZE.z * 0.5),
		"WallBackRight"
	)


func _build_exit_walkway() -> void:
	_make_collision_box(
		EXIT_WALKWAY_SIZE,
		EXIT_WALKWAY_CENTER + Vector3(0.0, -EXIT_WALKWAY_SIZE.y * 0.5, 0.0),
		"ExitWalkwayFloor"
	)
	_make_collision_box(
		Vector3(0.22, 1.0, EXIT_WALKWAY_SIZE.z),
		EXIT_WALKWAY_CENTER + Vector3(-EXIT_WALKWAY_SIZE.x * 0.5 + 0.11, 0.5, 0.0),
		"ExitWalkwayLeftRail"
	)
	_make_collision_box(
		Vector3(0.22, 1.0, EXIT_WALKWAY_SIZE.z),
		EXIT_WALKWAY_CENTER + Vector3(EXIT_WALKWAY_SIZE.x * 0.5 - 0.11, 0.5, 0.0),
		"ExitWalkwayRightRail"
	)
	_make_guide_strip(Vector3(0.0, 0.03, -9.0), Vector3(1.8, 0.06, 4.4), EXIT_COLOR)
	_make_guide_strip(Vector3(0.0, 0.03, -12.0), Vector3(1.3, 0.06, 1.0), EXIT_COLOR)
	_make_light(Vector3(-1.9, 1.4, -10.1), EXIT_COLOR, 0.5, 4.2)
	_make_light(Vector3(1.9, 1.4, -10.1), EXIT_COLOR, 0.5, 4.2)


func _make_collision_box(size: Vector3, position: Vector3, node_name: String) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collider.shape = shape
	body.add_child(collider)
	body.position = position
	gameplay_root.add_child(body)
	return body


func _make_blocker(position: Vector3, size: Vector3, color: Color, node_name: String) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	var mesh := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	mesh.mesh = box_mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	mesh.material_override = material
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collider.shape = shape
	body.add_child(mesh)
	body.add_child(collider)
	body.position = position
	gameplay_root.add_child(body)
	return body


func _make_light(position: Vector3, color: Color, energy: float, range_value: float) -> void:
	var light := OmniLight3D.new()
	light.position = position
	light.light_color = color
	light.light_energy = energy
	light.omni_range = range_value
	light_root.add_child(light)
