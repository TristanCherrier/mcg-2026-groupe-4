extends Node3D

const TERMINAL_SCENE = preload("res://Scenes/Actors/PuzzleTerminal.tscn")

# Position de spawn du monstre
const MONSTER_SPAWN = Vector3(4.5, 0.1, 4.5)

const GUIDE_COLOR = Color(0.2, 0.68, 0.9)
const SCREEN_A_COLOR = Color(0.25, 0.75, 1.0)
const SCREEN_B_COLOR = Color(0.98, 0.54, 0.24)
const SCREEN_C_COLOR = Color(0.26, 0.85, 0.52)
const TOTAL_TERMINALS = 3

const TERMINAL_SCREEN_PATHS = [
	NodePath("Tables/table2SB/table2/screen4"),
	NodePath("Tables/table6SB/table6/screen3"),
	NodePath("Tables/table13SB/table13/screen2")
]

var solved_count = 0
var completion_queued = false
var spawn_transform = Transform3D.IDENTITY
var terminal_screen_map: Dictionary = {}
var terminal_display_map: Dictionary = {}

@onready var player_root: Node3D = $Robot
@onready var player_ball: RigidBody3D = $Robot/ball_rb
@onready var hud: CanvasLayer = $HUD
@onready var architecture_root: Node3D = $Architecture
@onready var decor_root: Node3D = $Decor
@onready var light_root: Node3D = $AccentLights


func _ready() -> void:
	GameState.enter_level("Niveau 1 - Salle de TP", scene_file_path)
	GameState.set_next_level("res://Scenes/Levels/Arena.tscn")
	GameState.set_objective(_build_progress_objective())
	GameState.set_help("Robot : ZQSD pour rouler, souris pour regarder, V ou Molette pour changer de vue, Clic pour attaquer.")
	GameState.set_integrity(100.0)
	GameState.set_energy(100.0)
	hud.configure("Niveau 1 - Salle de TP", false, false)
	player_ball.fell.connect(_on_player_fell)
	_build_level()
	spawn_transform = Transform3D(Basis.IDENTITY.rotated(Vector3.UP, PI), Vector3.ZERO)
	player_ball.respawn_at(spawn_transform)
	GameState.push_message("Validez les 3 ecrans d'ordinateur dans la salle.", 4.0)

func _build_level() -> void:
	var screen_nodes: Array[Node3D] = []
	for path in TERMINAL_SCREEN_PATHS:
		var screen_node = get_node_or_null(path) as Node3D
		if screen_node != null:
			screen_nodes.append(screen_node)

	if screen_nodes.size() < TOTAL_TERMINALS:
		push_error("Impossible de trouver les 3 ecrans dans classroom.tscn.")
		return

	var terminal_a = _spawn_terminal_on_screen(
		screen_nodes[0],
		"Sequence energetique : 2, 4, 8, 16, ... quel nombre complete la suite ?",
		["24", "32", "18"],
		1,
		"Indice : la machine double sa puissance a chaque etape."
	)
	var terminal_b = _spawn_terminal_on_screen(
		screen_nodes[1],
		"Quel symbole chimique correspond au sodium utilise dans certains capteurs ?",
		["So", "Sn", "Na"],
		2,
		"Indice : pensez au tableau periodique."
	)
	var terminal_c = _spawn_terminal_on_screen(
		screen_nodes[2],
		"Pour reactiver le generateur, quel outil mesure la tension d'un circuit ?",
		["Le voltmetre", "Le barometre", "Le microscope"],
		0,
		"Indice : la reponse est liee a l'electricite."
	)

	terminal_a.solved_terminal.connect(_on_terminal_solved)
	terminal_b.solved_terminal.connect(_on_terminal_solved)
	terminal_c.solved_terminal.connect(_on_terminal_solved)

	_set_computer_screen_state(screen_nodes[0], SCREEN_A_COLOR, false)
	_set_computer_screen_state(screen_nodes[1], SCREEN_B_COLOR, false)
	_set_computer_screen_state(screen_nodes[2], SCREEN_C_COLOR, false)
	_make_screen_terminal_glow(screen_nodes[0], SCREEN_A_COLOR)
	_make_screen_terminal_glow(screen_nodes[1], SCREEN_B_COLOR)
	_make_screen_terminal_glow(screen_nodes[2], SCREEN_C_COLOR)

	for light_data in [
		{"pos": Vector3(-4.8, 3.8, 5.1), "color": Color(0.75, 0.9, 1.0), "energy": 0.55},
		{"pos": Vector3(0.0, 3.8, 5.1), "color": Color(0.75, 0.9, 1.0), "energy": 0.55},
		{"pos": Vector3(4.8, 3.8, 5.1), "color": Color(0.75, 0.9, 1.0), "energy": 0.55},
		{"pos": screen_nodes[0].global_position + Vector3(0.0, 0.35, 0.0), "color": SCREEN_A_COLOR, "energy": 0.45},
		{"pos": screen_nodes[1].global_position + Vector3(0.0, 0.35, 0.0), "color": SCREEN_B_COLOR, "energy": 0.45},
		{"pos": screen_nodes[2].global_position + Vector3(0.0, 0.35, 0.0), "color": SCREEN_C_COLOR, "energy": 0.45}
	]:
		_make_light(light_data.pos, light_data.color, light_data.energy, 4.8)


func _spawn_terminal_on_screen(screen_node: Node3D, question: String, answers: Array[String], correct_index: int, hint: String) -> Area3D:
	var terminal = TERMINAL_SCENE.instantiate()
	terminal.question = question
	terminal.answers = answers
	terminal.correct_index = correct_index
	terminal.objective_hint = hint
	terminal.screen_mode = true
	terminal.auto_open_on_approach = true
	screen_node.add_child(terminal)
	terminal.transform = Transform3D.IDENTITY.translated(Vector3(0.0, 0.0, 0.14))
	terminal.scale = Vector3(0.7, 0.7, 0.7)
	terminal_screen_map[terminal] = screen_node
	terminal_display_map[terminal] = _attach_display_overlay(screen_node)
	return terminal


func _on_terminal_solved(terminal: Area3D) -> void:
	var screen_node = terminal_screen_map.get(terminal, null) as Node3D
	if screen_node != null:
		_set_computer_screen_state(screen_node, SCREEN_C_COLOR, true)
	var display_overlay = terminal_display_map.get(terminal, null) as MeshInstance3D
	if display_overlay != null:
		_set_display_overlay_state(display_overlay, SCREEN_C_COLOR, true)

	solved_count += 1
	if solved_count < TOTAL_TERMINALS:
		GameState.set_objective(_build_progress_objective())
		GameState.push_message("Poste valide : %d / %d." % [solved_count, TOTAL_TERMINALS], 2.0)
		return

	completion_queued = true
	GameState.set_objective("Les 3 ecrans sont valides. Passage immediat au niveau 2.")
	GameState.push_message("Tous les terminaux sont valides. Passage au niveau 2.", 1.4)
	call_deferred("_go_to_level_2")


func _go_to_level_2() -> void:
	GameState.complete_level()


func _on_player_fell() -> void:
	GameState.apply_fall_penalty()
	GameState.push_message("Repositionnement dans la salle de TP.", 1.5)
	player_ball.respawn_at(spawn_transform)

func _make_guide_strip(_position: Vector3, size: Vector3, color: Color) -> void:
	var mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	mesh.material_override = material
	mesh.position = _position
	decor_root.add_child(mesh)


func _make_screen_terminal_glow(screen_node: Node3D, color: Color) -> void:
	var light = OmniLight3D.new()
	light.position = screen_node.global_position + Vector3(0.0, 0.22, 0.08)
	light.light_color = color
	light.light_energy = 2.4
	light.omni_range = 5.2
	light_root.add_child(light)


func _set_computer_screen_state(screen_node: Node3D, color: Color, solved: bool) -> void:
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.96, 1.0, 0.98, 1.0) if solved else Color(0.28, 0.6, 0.86, 1.0)
	material.emission_enabled = true
	material.emission = Color(0.52, 1.0, 0.74, 1.0) if solved else color.lightened(0.18)
	material.emission_energy_multiplier = 3.4 if solved else 5.4
	material.roughness = 0.02
	_apply_material_to_screen_meshes(screen_node, material)


func _attach_display_overlay(screen_node: Node3D) -> MeshInstance3D:
	var overlay = MeshInstance3D.new()
	overlay.name = "MissionDisplayOverlay"
	var mesh = QuadMesh.new()
	mesh.size = Vector2(0.52, 0.32)
	overlay.mesh = mesh
	overlay.position = Vector3(0.0, 0.19, 0.038)
	screen_node.add_child(overlay)
	return overlay


func _set_display_overlay_state(overlay: MeshInstance3D, color: Color, solved: bool) -> void:
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.96, 1.0, 0.98, 1.0) if solved else Color(0.3, 0.64, 0.9, 1.0)
	material.emission_enabled = true
	material.emission = Color(0.52, 1.0, 0.76, 1.0) if solved else color.lightened(0.22)
	material.emission_energy_multiplier = 4.4 if solved else 7.0
	material.roughness = 0.01
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	overlay.material_override = material


func _apply_material_to_screen_meshes(node: Node, material: Material) -> void:
	if node is MeshInstance3D:
		(node as MeshInstance3D).material_override = material
	for child in node.get_children():
		_apply_material_to_screen_meshes(child, material)


func _build_progress_objective() -> String:
	return "Validez les 3 ecrans scientifiques (%d / %d) dans la salle." % [solved_count, TOTAL_TERMINALS]

func _make_light(_position: Vector3, color: Color, energy: float, range_value: float) -> void:
	var light = OmniLight3D.new()
	light.position = _position
	light.light_color = color
	light.light_energy = energy
	light.omni_range = range_value
	light_root.add_child(light)
