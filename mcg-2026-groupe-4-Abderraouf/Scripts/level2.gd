extends Node3D

const CHECKPOINT_SCENE := preload("res://Scenes/Actors/Checkpoint.tscn")
const FINISH_SCENE := preload("res://Scenes/Actors/FinishZone.tscn")
const TURRET_SCENE := preload("res://Scenes/Actors/Turret.tscn")
const MOVING_OBSTACLE_SCENE := preload("res://Scenes/Actors/MovingObstacle.tscn")

const FLOOR_COLOR := Color(0.14, 0.15, 0.18)
const CEILING_COLOR := Color(0.24, 0.26, 0.3)
const WALL_COLOR := Color(0.2, 0.23, 0.28)
const METAL_COLOR := Color(0.44, 0.48, 0.54)
const BLUE_ACCENT := Color(0.2, 0.68, 0.94)
const ORANGE_ACCENT := Color(0.95, 0.47, 0.18)
const HAZARD_COLOR := Color(0.9, 0.34, 0.14)
const TRACK_WIDTH := 16.2
const TRACK_LENGTH := 112.0
const TRACK_CENTER_Z := -52.0
const WALL_THICKNESS := 0.42
const RESPAWN_SIDE_LIMIT := 7.35
const REQUIRED_CHECKPOINTS := 3

var checkpoints_hit := 0
var collision_cooldown := 0.0
var respawn_transform := Transform3D.IDENTITY
var respawn_cooldown := 0.0
var level_started := false
var moving_obstacles: Array[Node3D] = []
var turrets: Array[Node3D] = []

@onready var hud: CanvasLayer = $HUD
@onready var car_root: Node3D = $Vehicle
@onready var car_body: RigidBody3D = $Vehicle/CarRB
@onready var architecture_root: Node3D = $Architecture
@onready var decor_root: Node3D = $Decor
@onready var gameplay_root: Node3D = $GameplayNodes
@onready var npc_root: Node3D = $NPCs
@onready var light_root: Node3D = $AccentLights


func _ready() -> void:
	GameState.enter_level("Niveau 2 - Couloir motorisé", scene_file_path)
	GameState.set_next_level("res://Scenes/Levels/Level3.tscn")
	GameState.set_objective("Passez les 3 checkpoints puis atteignez l'arrivée. Chaque checkpoint répare le véhicule.")
	GameState.set_help("Z pour accélérer, Q/D pour diriger, espace pour frein à main.")
	GameState.set_integrity(100.0)
	GameState.set_energy(100.0)
	hud.configure("Niveau 2 - Couloir motorisé", true, false)
	car_root.add_to_group("car_player")
	car_body.add_to_group("car_player")
	car_body.contact_monitor = true
	car_body.max_contacts_reported = 10
	car_body.body_entered.connect(_on_car_body_entered)
	var car_camera := car_root.get_node("cam") as Camera3D
	car_camera.current = true
	_build_level()
	respawn_transform = Transform3D(Basis.IDENTITY, Vector3(0.0, car_body.global_position.y, -8.8))
	if car_body.has_method("reset_vehicle"):
		car_body.call("reset_vehicle", respawn_transform)
	if car_camera.has_method("snap_to_target"):
		car_camera.snap_to_target()
	_set_level_started(true)
	call_deferred("_refresh_start_camera")
	GameState.push_message("Course lancee : suis la piste orange et passe les checkpoints.", 3.0)


func _physics_process(delta: float) -> void:
	collision_cooldown = maxf(0.0, collision_cooldown - delta)
	respawn_cooldown = maxf(0.0, respawn_cooldown - delta)
	if not level_started:
		if _wants_to_start_level():
			_set_level_started(true)
		return
	if respawn_cooldown > 0.0:
		return
	if car_body.global_position.y < -6.0 or abs(car_body.global_position.x) > RESPAWN_SIDE_LIMIT:
		_respawn_car(true)
		return


func _build_level() -> void:
	_make_box(Vector3(TRACK_WIDTH, 0.32, TRACK_LENGTH), Vector3(0, -0.16, TRACK_CENTER_Z), FLOOR_COLOR, architecture_root, "Floor")
	_make_box(Vector3(TRACK_WIDTH, 0.28, TRACK_LENGTH), Vector3(0, 5.15, TRACK_CENTER_Z), CEILING_COLOR, architecture_root, "Ceiling")
	_make_box(Vector3(WALL_THICKNESS, 5.1, TRACK_LENGTH), Vector3(-7.8, 2.35, TRACK_CENTER_Z), WALL_COLOR, architecture_root, "WallLeft")
	_make_box(Vector3(WALL_THICKNESS, 5.1, TRACK_LENGTH), Vector3(7.8, 2.35, TRACK_CENTER_Z), WALL_COLOR, architecture_root, "WallRight")
	_make_box(Vector3(TRACK_WIDTH, 5.1, WALL_THICKNESS), Vector3(0, 2.35, 3.8), WALL_COLOR, architecture_root, "WallStart")
	_make_box(Vector3(TRACK_WIDTH, 5.1, WALL_THICKNESS), Vector3(0, 2.35, -107.8), WALL_COLOR, architecture_root, "WallEnd")
	_make_test_lane()
	_make_service_bays()

	for hazard_data in [
		{"size": Vector3(1.1, 1.1, 1.1), "position": Vector3(-5.1, 0.55, -18.0)},
		{"size": Vector3(1.1, 1.1, 1.1), "position": Vector3(5.1, 0.55, -31.0)},
		{"size": Vector3(1.1, 1.1, 1.1), "position": Vector3(-5.0, 0.55, -57.0)},
		{"size": Vector3(1.1, 1.1, 1.1), "position": Vector3(5.0, 0.55, -70.0)},
		{"size": Vector3(1.2, 1.2, 1.2), "position": Vector3(5.1, 0.6, -92.0)}
	]:
		_make_hazard_box(hazard_data.size, hazard_data.position)

	var moving_a := MOVING_OBSTACLE_SCENE.instantiate()
	moving_a.position = Vector3(0, 1.0, -42.0)
	moving_a.distance = 0.42
	moving_a.speed = 0.42
	moving_a.axis = Vector3(1, 0, 0)
	moving_a.add_to_group("hazard_obstacle")
	gameplay_root.add_child(moving_a)
	moving_obstacles.append(moving_a)

	var moving_b := MOVING_OBSTACLE_SCENE.instantiate()
	moving_b.position = Vector3(0, 1.0, -80.0)
	moving_b.distance = 0.5
	moving_b.speed = 0.46
	moving_b.axis = Vector3(1, 0, 0)
	moving_b.add_to_group("hazard_obstacle")
	gameplay_root.add_child(moving_b)
	moving_obstacles.append(moving_b)

	_spawn_checkpoint(Vector3(0, 1.2, -23.0))
	_spawn_checkpoint(Vector3(0, 1.2, -50.0))
	_spawn_checkpoint(Vector3(0, 1.2, -79.0))

	var finish := FINISH_SCENE.instantiate()
	finish.position = Vector3(0, 0.12, -99.5)
	finish.target_group = "car_player"
	finish.finish_entered.connect(_on_finish_entered)
	gameplay_root.add_child(finish)

	_spawn_turret(Vector3(-6.2, 1.1, -22.0), Vector3.RIGHT)
	_spawn_turret(Vector3(6.2, 1.1, -48.0), Vector3.LEFT)
	_spawn_turret(Vector3(-6.2, 1.1, -74.0), Vector3.RIGHT)

	for z in [2.0, -16.0, -34.0, -52.0, -70.0, -88.0, -104.0]:
		_make_light(Vector3(0, 4.45, z), Color(1.0, 0.94, 0.88), 0.98, 9.5)
	for z in [-8.0, -26.0, -44.0, -62.0, -80.0, -98.0]:
		_make_light(Vector3(-6.6, 1.8, z), Color(0.26, 0.75, 1.0), 0.44, 4.2)
		_make_light(Vector3(6.6, 1.8, z), Color(1.0, 0.54, 0.24), 0.44, 4.2)


func _make_test_lane() -> void:
	for z in range(0, 21):
		var lane_z := 1.5 - float(z) * 5.2
		_make_visual_box(Vector3(0.24, 0.03, 2.4), Vector3(0, 0.05, lane_z), ORANGE_ACCENT, decor_root, "CenterDash", ORANGE_ACCENT)
		_make_visual_box(Vector3(0.18, 0.03, 2.4), Vector3(-4.2, 0.05, lane_z), BLUE_ACCENT, decor_root, "LeftGuide", BLUE_ACCENT)
		_make_visual_box(Vector3(0.18, 0.03, 2.4), Vector3(4.2, 0.05, lane_z), BLUE_ACCENT, decor_root, "RightGuide", BLUE_ACCENT)
	for x in [-6.95, 6.95]:
		_make_visual_box(Vector3(0.18, 0.42, 108.0), Vector3(x, 0.24, -52.0), METAL_COLOR, decor_root, "Rail")
		_make_visual_box(Vector3(0.08, 0.16, 108.0), Vector3(x, 1.05, -52.0), BLUE_ACCENT if x < 0 else ORANGE_ACCENT, decor_root, "RailGlow", BLUE_ACCENT if x < 0 else ORANGE_ACCENT)


func _make_service_bays() -> void:
	for z in [-12.0, -36.0, -60.0, -84.0]:
		_make_bay(Vector3(-7.0, 0.0, z), false, BLUE_ACCENT)
		_make_bay(Vector3(7.0, 0.0, z - 4.0), true, ORANGE_ACCENT)


func _make_bay(anchor: Vector3, mirrored: bool, accent: Color) -> void:
	var bay := Node3D.new()
	bay.name = "ServiceBay"
	bay.position = anchor
	bay.rotation.y = PI if mirrored else 0.0
	decor_root.add_child(bay)

	_make_box(Vector3(0.8, 1.4, 3.0), Vector3(0, 0.7, 0), METAL_COLOR, bay, "Cabinet")
	_make_visual_box(Vector3(0.1, 1.0, 1.6), Vector3(0.35, 1.15, 0), Color(0.18, 0.22, 0.3), bay, "DisplayWall", accent)
	_make_visual_box(Vector3(0.22, 0.22, 0.22), Vector3(0.15, 0.55, -0.9), Color(0.66, 0.7, 0.74), bay, "DeviceA", accent)
	_make_visual_box(Vector3(0.22, 0.22, 0.22), Vector3(0.15, 0.55, 0.0), Color(0.66, 0.7, 0.74), bay, "DeviceB", accent)
	_make_visual_box(Vector3(0.22, 0.22, 0.22), Vector3(0.15, 0.55, 0.9), Color(0.66, 0.7, 0.74), bay, "DeviceC", accent)


func _spawn_checkpoint(position: Vector3) -> void:
	var checkpoint := CHECKPOINT_SCENE.instantiate()
	checkpoint.position = position
	checkpoint.target_group = "car_player"
	checkpoint.checkpoint_reached.connect(_on_checkpoint_reached)
	gameplay_root.add_child(checkpoint)


func _spawn_turret(position: Vector3, fire_direction: Vector3) -> void:
	var turret := TURRET_SCENE.instantiate()
	turret.position = position
	turret.fire_interval = 5.8
	turret.fire_direction = fire_direction
	turret.projectile_message = "Projectile latéral dans le couloir."
	gameplay_root.add_child(turret)
	turrets.append(turret)
func _on_checkpoint_reached(checkpoint: Area3D) -> void:
	checkpoints_hit += 1
	respawn_transform = Transform3D(Basis.IDENTITY, checkpoint.global_position + Vector3(0, 0.55, 4.0))
	GameState.repair_integrity(28.0)
	GameState.push_message("Checkpoint %d / %d valide. Integrite restauree." % [checkpoints_hit, REQUIRED_CHECKPOINTS], 2.2)


func _on_finish_entered(_body: Node) -> void:
	if checkpoints_hit >= REQUIRED_CHECKPOINTS:
		GameState.complete_level()
	else:
		GameState.push_message("Il manque encore des checkpoints avant l'arrivee.")


func _on_car_body_entered(body: Node) -> void:
	if collision_cooldown > 0.0:
		return
	if body.is_in_group("hazard_obstacle"):
		collision_cooldown = 1.25
		GameState.damage_integrity(3.0, "Collision avec un obstacle du couloir.")


func _respawn_car(apply_penalty: bool) -> void:
	respawn_cooldown = 1.2
	if apply_penalty:
		GameState.apply_fall_penalty()
		GameState.damage_integrity(4.0, "Le vehicule a quitte la zone securisee du couloir.")
		if GameState.integrity <= 0.0:
			return
	if car_body.has_method("reset_vehicle"):
		car_body.call("reset_vehicle", respawn_transform)
	var car_camera := car_root.get_node_or_null("cam")
	if car_camera != null and car_camera.has_method("snap_to_target"):
		car_camera.snap_to_target()


func _wants_to_start_level() -> bool:
	return (
		Input.is_action_just_pressed("Gas")
		or Input.is_action_just_pressed("Brake")
		or Input.is_action_just_pressed("Steer_Left")
		or Input.is_action_just_pressed("Steer_Right")
		or Input.is_action_just_pressed("E-Brake")
	)


func _set_level_started(value: bool) -> void:
	level_started = value
	if car_body.has_method("set_drive_enabled"):
		car_body.call("set_drive_enabled", value)
	if car_body.has_method("reset_vehicle"):
		car_body.call("reset_vehicle", respawn_transform)
	var car_camera := car_root.get_node_or_null("cam")
	if car_camera != null and car_camera.has_method("snap_to_target"):
		car_camera.snap_to_target()
	for obstacle in moving_obstacles:
		if obstacle != null and obstacle.has_method("set_active"):
			obstacle.set_active(value)
	for turret in turrets:
		if turret != null and turret.has_method("set_active"):
			turret.set_active(value)


func _refresh_start_camera() -> void:
	var car_camera := car_root.get_node_or_null("cam")
	if car_camera != null and car_camera.has_method("snap_to_target"):
		car_camera.snap_to_target()


func _make_box(
	size: Vector3,
	position: Vector3,
	color: Color,
	parent: Node3D,
	node_name := "StaticBox",
	emission_color := Color(0, 0, 0, 1),
	metallic := 0.1,
	roughness := 0.62
) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	var mesh := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	mesh.mesh = box_mesh
	mesh.material_override = _create_material(color, emission_color, metallic, roughness)
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collider.shape = shape
	body.add_child(mesh)
	body.add_child(collider)
	body.position = position
	parent.add_child(body)
	return body


func _make_visual_box(
	size: Vector3,
	position: Vector3,
	color: Color,
	parent: Node3D,
	node_name := "VisualBox",
	emission_color := Color(0, 0, 0, 1),
	metallic := 0.08,
	roughness := 0.44
) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = node_name
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	mesh.mesh = box_mesh
	mesh.material_override = _create_material(color, emission_color, metallic, roughness)
	mesh.position = position
	parent.add_child(mesh)
	return mesh


func _make_hazard_box(size: Vector3, position: Vector3) -> void:
	var body := _make_box(size, position, HAZARD_COLOR, gameplay_root, "HazardBox", ORANGE_ACCENT, 0.08, 0.38)
	body.add_to_group("hazard_obstacle")


func _create_material(color: Color, emission_color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	if emission_color != Color(0, 0, 0, 1):
		material.emission_enabled = true
		material.emission = emission_color
	return material


func _make_light(position: Vector3, color: Color, energy: float, range_value: float) -> void:
	var light := OmniLight3D.new()
	light.position = position
	light.light_color = color
	light.light_energy = energy
	light.omni_range = range_value
	light_root.add_child(light)
