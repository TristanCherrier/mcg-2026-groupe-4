extends Node3D

const RING_SCENE := preload("res://Scenes/Actors/CollectibleRing.tscn")
const FINISH_SCENE := preload("res://Scenes/Actors/FinishZone.tscn")
const TURRET_SCENE := preload("res://Scenes/Actors/Turret.tscn")
const MONSTER_SCENE := preload("res://Scenes/Actors/MonsterRobot.tscn")

const FLOOR_COLOR := Color(0.84, 0.86, 0.88)
const WALL_COLOR := Color(0.76, 0.8, 0.84)
const CEILING_COLOR := Color(0.96, 0.98, 1.0)
const PLATFORM_COLOR := Color(0.33, 0.38, 0.45)
const BLUE_ACCENT := Color(0.24, 0.72, 0.98)
const ORANGE_ACCENT := Color(0.96, 0.48, 0.18)
const GREEN_ACCENT := Color(0.24, 0.84, 0.54)
const HAZARD_COLOR := Color(0.9, 0.34, 0.16)

var rings_hit := 0
var collision_cooldown := 0.0
var respawn_transform := Transform3D.IDENTITY

@onready var hud: CanvasLayer = $HUD
@onready var ship_root: Node3D = $ShipRig
@onready var ship_body: RigidBody3D = $ShipRig/ship_rb
@onready var architecture_root: Node3D = $Architecture
@onready var decor_root: Node3D = $Decor
@onready var gameplay_root: Node3D = $GameplayNodes
@onready var npc_root: Node3D = $NPCs
@onready var light_root: Node3D = $AccentLights


func _ready() -> void:
	GameState.enter_level("Niveau 3 - Atrium au propulseur", scene_file_path)
	GameState.set_next_level("")
	GameState.set_objective("Collectez les 5 anneaux énergétiques puis rejoignez la plateforme sommitale.")
	GameState.set_help("Z pour pousser, souris pour orienter le réacteur, gérez votre énergie.")
	GameState.set_integrity(100.0)
	GameState.set_energy(100.0)
	hud.configure("Niveau 3 - Atrium au propulseur", true, true)
	ship_root.add_to_group("ship_player")
	ship_body.add_to_group("ship_player")
	ship_body.contact_monitor = true
	ship_body.max_contacts_reported = 10
	ship_body.body_entered.connect(_on_ship_body_entered)
	respawn_transform = ship_body.global_transform
	var ship_camera := ship_root.get_node("ship_cam") as Camera3D
	ship_camera.current = true
	_build_level()


func _physics_process(delta: float) -> void:
	collision_cooldown = maxf(0.0, collision_cooldown - delta)
	if ship_body.global_position.y < -6.0 or absf(ship_body.global_position.x) > 14.5 or absf(ship_body.global_position.z) > 14.5:
		_respawn_ship(true)


func _build_level() -> void:
	_make_box(Vector3(16.0, 0.3, 16.0), Vector3(0, -0.18, 0), FLOOR_COLOR, architecture_root, "Floor")
	_make_box(Vector3(16.0, 0.28, 16.0), Vector3(0, 31.8, 0), CEILING_COLOR, architecture_root, "Ceiling")
	_make_box(Vector3(0.42, 32.0, 16.0), Vector3(-7.9, 15.8, 0), WALL_COLOR, architecture_root, "WallLeft")
	_make_box(Vector3(0.42, 32.0, 16.0), Vector3(7.9, 15.8, 0), WALL_COLOR, architecture_root, "WallRight")
	_make_box(Vector3(16.0, 32.0, 0.42), Vector3(0, 15.8, -7.9), WALL_COLOR, architecture_root, "WallBack")
	_make_box(Vector3(16.0, 32.0, 0.42), Vector3(0, 15.8, 7.9), WALL_COLOR, architecture_root, "WallFront")
	_make_vertical_atrium_lights()

	_make_platform(Vector3(4.2, 0.4, 4.2), Vector3(-4.5, 6.0, 4.0), BLUE_ACCENT)
	_make_platform(Vector3(4.2, 0.4, 4.2), Vector3(4.5, 11.0, -4.0), ORANGE_ACCENT)
	_make_platform(Vector3(4.2, 0.4, 4.2), Vector3(-4.5, 16.0, -4.0), BLUE_ACCENT)
	_make_platform(Vector3(4.2, 0.4, 4.2), Vector3(4.5, 21.0, 4.0), ORANGE_ACCENT)
	_make_platform(Vector3(5.2, 0.4, 5.2), Vector3(0.0, 28.0, 0.0), GREEN_ACCENT)

	_make_hazard_box(Vector3(1.0, 4.0, 1.0), Vector3(0.0, 8.0, -2.5))
	_make_hazard_box(Vector3(1.0, 4.0, 1.0), Vector3(2.5, 18.0, 0.0))

	_spawn_ring(Vector3(0.0, 2.4, -4.2))
	_spawn_ring(Vector3(4.2, 7.8, 0.0))
	_spawn_ring(Vector3(-4.0, 13.0, 2.0))
	_spawn_ring(Vector3(3.0, 18.7, -3.2))
	_spawn_ring(Vector3(0.0, 24.4, 4.2))

	_spawn_turret(Vector3(-4.5, 6.6, 5.0))
	_spawn_turret(Vector3(4.5, 11.6, -5.0))
	_spawn_turret(Vector3(-4.5, 16.6, -5.0))
	_spawn_turret(Vector3(4.5, 21.6, 5.0))

	_spawn_monster(Vector3(-4.5, 6.4, 2.2), Vector3(0, 0, 1))
	_spawn_monster(Vector3(4.5, 11.4, -2.2), Vector3(0, 0, -1))
	_spawn_monster(Vector3(-4.5, 16.4, -2.2), Vector3(0, 0, -1))
	_spawn_monster(Vector3(4.5, 21.4, 2.2), Vector3(0, 0, 1))

	var finish := FINISH_SCENE.instantiate()
	finish.position = Vector3(0, 28.25, 0)
	finish.target_group = "ship_player"
	finish.finish_entered.connect(_on_finish_entered)
	gameplay_root.add_child(finish)

	for y in [4.0, 10.0, 16.0, 22.0, 28.0]:
		_make_light(Vector3(0, y, 0), Color(1.0, 0.95, 0.88), 0.98, 9.8)


func _make_vertical_atrium_lights() -> void:
	for y in [3.5, 8.5, 13.5, 18.5, 23.5, 28.5]:
		_make_visual_box(Vector3(0.12, 2.0, 0.28), Vector3(-7.55, y, -5.4), BLUE_ACCENT, decor_root, "WallBeam", BLUE_ACCENT)
		_make_visual_box(Vector3(0.12, 2.0, 0.28), Vector3(-7.55, y, 5.4), BLUE_ACCENT, decor_root, "WallBeam", BLUE_ACCENT)
		_make_visual_box(Vector3(0.12, 2.0, 0.28), Vector3(7.55, y, -5.4), ORANGE_ACCENT, decor_root, "WallBeam", ORANGE_ACCENT)
		_make_visual_box(Vector3(0.12, 2.0, 0.28), Vector3(7.55, y, 5.4), ORANGE_ACCENT, decor_root, "WallBeam", ORANGE_ACCENT)
	for y in [2.5, 7.5, 12.5, 17.5, 22.5]:
		_make_visual_box(Vector3(0.3, 1.8, 0.12), Vector3(-5.9, y, -7.55), Color(0.7, 0.74, 0.8), decor_root, "VentDetail")
		_make_visual_box(Vector3(0.3, 1.8, 0.12), Vector3(5.9, y, 7.55), Color(0.7, 0.74, 0.8), decor_root, "VentDetail")


func _make_platform(size: Vector3, position: Vector3, accent: Color) -> void:
	_make_box(size, position, PLATFORM_COLOR, architecture_root, "Platform")
	_make_visual_box(Vector3(size.x - 0.36, 0.06, 0.16), position + Vector3(0, 0.24, -size.z * 0.5 + 0.12), accent, decor_root, "FrontEdge", accent)
	_make_visual_box(Vector3(size.x - 0.36, 0.06, 0.16), position + Vector3(0, 0.24, size.z * 0.5 - 0.12), accent, decor_root, "BackEdge", accent)
	_make_visual_box(Vector3(0.16, 0.06, size.z - 0.36), position + Vector3(-size.x * 0.5 + 0.12, 0.24, 0), accent, decor_root, "LeftEdge", accent)
	_make_visual_box(Vector3(0.16, 0.06, size.z - 0.36), position + Vector3(size.x * 0.5 - 0.12, 0.24, 0), accent, decor_root, "RightEdge", accent)


func _spawn_ring(position: Vector3) -> void:
	var ring := RING_SCENE.instantiate()
	ring.position = position
	ring.ring_collected.connect(_on_ring_collected)
	gameplay_root.add_child(ring)


func _spawn_turret(position: Vector3) -> void:
	var turret := TURRET_SCENE.instantiate()
	turret.position = position
	turret.fire_interval = 2.4
	turret.tracking_group = "ship_player"
	turret.projectile_message = "Impact d'un sentinelle aérien."
	gameplay_root.add_child(turret)


func _spawn_monster(position: Vector3, patrol_axis: Vector3) -> void:
	var monster := MONSTER_SCENE.instantiate()
	monster.position = position
	monster.patrol_axis = patrol_axis
	monster.patrol_distance = 0.3
	npc_root.add_child(monster)


func _on_ring_collected(ring: Area3D) -> void:
	rings_hit += 1
	respawn_transform = Transform3D(Basis.IDENTITY, ring.global_position + Vector3(0, 0.6, 0))
	if rings_hit < 5:
		GameState.set_objective("Anneaux récupérés : %d / 5. Continuez vers le sommet." % rings_hit)
	else:
		GameState.set_objective("Tous les anneaux sont actifs. Rejoignez maintenant la plateforme sommitale.")
		GameState.push_message("Énergie stabilisée : atterrissez sur la plateforme supérieure.", 3.0)


func _on_finish_entered(_body: Node) -> void:
	if rings_hit >= 5:
		GameState.complete_level()
	else:
		GameState.push_message("L'atterrissage final demande d'abord les 5 anneaux.")


func _on_ship_body_entered(body: Node) -> void:
	if collision_cooldown > 0.0:
		return
	if body.is_in_group("hazard_obstacle"):
		collision_cooldown = 0.75
		GameState.damage_integrity(12.0, "Collision avec une structure instable.")


func _respawn_ship(apply_penalty: bool) -> void:
	if apply_penalty:
		GameState.apply_fall_penalty()
		GameState.damage_integrity(8.0, "Perte de contrôle dans l'atrium.")
		if GameState.integrity <= 0.0:
			return
	ship_body.global_transform = respawn_transform
	ship_body.linear_velocity = Vector3.ZERO
	ship_body.angular_velocity = Vector3.ZERO


func _make_box(
	size: Vector3,
	position: Vector3,
	color: Color,
	parent: Node3D,
	node_name := "StaticBox",
	emission_color := Color(0, 0, 0, 1),
	metallic := 0.08,
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
	roughness := 0.42
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
	var body := _make_box(size, position, HAZARD_COLOR, gameplay_root, "HazardBox", ORANGE_ACCENT, 0.08, 0.36)
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
