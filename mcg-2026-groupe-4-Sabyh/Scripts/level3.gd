extends Node3D

const RING_SCENE := preload("res://Scenes/Actors/CollectibleRing.tscn")
const FINISH_SCENE := preload("res://Scenes/Actors/FinishZone.tscn")

const FLOOR_COLOR := Color(0.04, 0.05, 0.08)
const WALL_COLOR := Color(0.12, 0.16, 0.22)
const CEILING_COLOR := Color(0.78, 0.84, 0.92)
const PLATFORM_COLOR := Color(0.18, 0.22, 0.28)
const BLUE_ACCENT := Color(0.14, 0.74, 1.0)
const ORANGE_ACCENT := Color(1.0, 0.52, 0.18)
const GREEN_ACCENT := Color(0.22, 0.95, 0.66)
const REQUIRED_RINGS := 3

var rings_hit := 0
var collision_cooldown := 0.0
var respawn_transform := Transform3D.IDENTITY

@onready var hud: CanvasLayer = $HUD
@onready var ship_root: Node3D = $ShipRig
@onready var ship_body: RigidBody3D = $ShipRig/ship_rb
@onready var architecture_root: Node3D = $Architecture
@onready var decor_root: Node3D = $Decor
@onready var gameplay_root: Node3D = $GameplayNodes
@onready var light_root: Node3D = $AccentLights


func _ready() -> void:
	GameState.enter_level("Niveau 3 - Réacteur Mirande", scene_file_path)
	GameState.set_next_level("")
	GameState.set_objective("Décollez, suivez les balises du reacteur, traversez les 3 anneaux puis posez-vous sur la couronne verte.")
	GameState.set_help("Z monte et avance, S redescend, Q et D decalent, espace donne une forte poussee. Posez-vous sur les plateformes lumineuses si besoin.")
	GameState.set_integrity(100.0)
	GameState.set_energy(100.0)
	hud.configure("Niveau 3 - Réacteur Mirande", true, true)

	ship_root.add_to_group("ship_player")
	ship_body.add_to_group("ship_player")
	ship_body.contact_monitor = true
	ship_body.max_contacts_reported = 10
	ship_body.body_entered.connect(_on_ship_body_entered)

	var ship_camera := ship_root.get_node("ship_cam") as Camera3D
	ship_camera.current = true

	_build_level()

	ship_body.global_transform = Transform3D(Basis.IDENTITY, Vector3(0.0, 1.05, 6.1))
	ship_body.linear_velocity = Vector3.ZERO
	ship_body.angular_velocity = Vector3.ZERO
	respawn_transform = ship_body.global_transform
	_snap_ship_camera()

	GameState.push_message("Décolle de la plate-forme, suis les balises suspendues et traverse les anneaux un par un.", 4.2)


func _physics_process(delta: float) -> void:
	collision_cooldown = maxf(0.0, collision_cooldown - delta)
	if ship_body.global_position.y < -5.0 or absf(ship_body.global_position.x) > 20.0 or absf(ship_body.global_position.z) > 20.0:
		_respawn_ship(true)


func _build_level() -> void:
	_make_box(Vector3(26.0, 0.45, 26.0), Vector3(0, -0.22, 0), FLOOR_COLOR, architecture_root, "Floor")
	_make_box(Vector3(26.0, 0.4, 26.0), Vector3(0, 40.2, 0), CEILING_COLOR, architecture_root, "Ceiling")
	_make_box(Vector3(0.45, 40.0, 26.0), Vector3(-12.75, 19.9, 0), WALL_COLOR, architecture_root, "WallLeft")
	_make_box(Vector3(0.45, 40.0, 26.0), Vector3(12.75, 19.9, 0), WALL_COLOR, architecture_root, "WallRight")
	_make_box(Vector3(26.0, 40.0, 0.45), Vector3(0, 19.9, -12.75), WALL_COLOR, architecture_root, "WallBack")
	_make_box(Vector3(26.0, 40.0, 0.45), Vector3(0, 19.9, 12.75), WALL_COLOR, architecture_root, "WallFront")

	_make_launch_pad()
	_make_platform(Vector3(8.8, 0.42, 6.8), Vector3(-4.2, 5.3, 3.9), BLUE_ACCENT)
	_make_platform(Vector3(8.6, 0.42, 6.4), Vector3(4.4, 13.7, -0.2), ORANGE_ACCENT)
	_make_platform(Vector3(8.2, 0.42, 6.2), Vector3(-3.5, 22.0, -3.3), BLUE_ACCENT)
	_make_platform(Vector3(10.2, 0.42, 10.2), Vector3(0.0, 31.0, 0.0), GREEN_ACCENT)

	_make_bridge(Vector3(-2.0, 2.7, 5.0), Vector3(4.6, 0.24, 1.5), BLUE_ACCENT)
	_make_bridge(Vector3(0.6, 9.4, 1.8), Vector3(6.9, 0.24, 1.4), ORANGE_ACCENT)
	_make_bridge(Vector3(0.4, 17.9, -1.6), Vector3(6.4, 0.24, 1.4), BLUE_ACCENT)
	_make_bridge(Vector3(-1.5, 26.4, -1.5), Vector3(4.0, 0.24, 1.3), GREEN_ACCENT)

	_make_reactor_core()
	_make_energy_spiral(3.0, BLUE_ACCENT, 0.0)
	_make_energy_spiral(4.2, ORANGE_ACCENT, PI * 0.72)
	_make_energy_spiral(5.3, GREEN_ACCENT, PI * 1.18)
	_make_side_fins()
	_make_crown_arch()
	_make_route_guides()

	_make_energy_gate(Vector3(-3.2, 7.0, 2.8), BLUE_ACCENT, 1.7)
	_make_energy_gate(Vector3(3.6, 15.6, -0.4), ORANGE_ACCENT, 1.8)
	_make_energy_gate(Vector3(-2.8, 23.8, -3.0), GREEN_ACCENT, 1.9)

	_spawn_ring(Vector3(-3.2, 7.0, 2.8), 1.55)
	_spawn_ring(Vector3(3.6, 15.6, -0.4), 1.66)
	_spawn_ring(Vector3(-2.8, 23.8, -3.0), 1.78)

	var finish := FINISH_SCENE.instantiate()
	finish.position = Vector3(0, 31.35, 0)
	finish.scale = Vector3(2.2, 1.0, 2.2)
	finish.target_group = "ship_player"
	finish.finish_entered.connect(_on_finish_entered)
	gameplay_root.add_child(finish)

	for y in [2.0, 6.0, 10.0, 14.0, 18.0, 22.0, 26.0, 30.0, 34.0, 38.0]:
		_make_light(Vector3(0, y, 0), Color(1.0, 0.95, 0.9), 1.0, 12.8)
	_make_light(Vector3(-3.2, 7.0, 2.8), BLUE_ACCENT, 1.25, 8.2)
	_make_light(Vector3(3.6, 15.6, -0.4), ORANGE_ACCENT, 1.25, 8.2)
	_make_light(Vector3(-2.8, 23.8, -3.0), GREEN_ACCENT, 1.25, 8.2)
	_make_light(Vector3(0.0, 31.3, 0.0), GREEN_ACCENT, 1.4, 9.0)


func _make_launch_pad() -> void:
	_make_platform(Vector3(10.4, 0.42, 10.4), Vector3(0.0, 0.2, 6.0), BLUE_ACCENT)
	_make_visual_box(Vector3(0.32, 0.08, 7.4), Vector3(0.0, 0.46, 5.1), ORANGE_ACCENT, decor_root, "LaunchSpine", ORANGE_ACCENT)
	_make_visual_box(Vector3(5.6, 0.08, 0.18), Vector3(0.0, 0.46, 2.4), GREEN_ACCENT, decor_root, "LaunchTag", GREEN_ACCENT)
	_make_visual_box(Vector3(0.18, 0.08, 2.8), Vector3(-1.25, 0.46, 1.2), GREEN_ACCENT, decor_root, "ArrowL", GREEN_ACCENT)
	_make_visual_box(Vector3(0.18, 0.08, 2.8), Vector3(1.25, 0.46, 1.2), GREEN_ACCENT, decor_root, "ArrowR", GREEN_ACCENT)
	_make_visual_box(Vector3(6.0, 0.08, 0.18), Vector3(0.0, 0.46, 7.8), BLUE_ACCENT, decor_root, "StartGuide", BLUE_ACCENT)


func _make_reactor_core() -> void:
	_make_energy_tube(Vector3(0.0, 18.8, 0.0), 34.0, 1.25, BLUE_ACCENT, 0.12)
	_make_energy_tube(Vector3(0.0, 18.8, 0.0), 34.0, 0.7, ORANGE_ACCENT, 0.16)

	for y in [4.2, 9.6, 15.0, 20.4, 25.8, 31.2, 36.6]:
		_make_reactor_halo(y, 3.8, BLUE_ACCENT)
		_make_reactor_halo(y + 0.95, 2.35, ORANGE_ACCENT)

	for point in [
		Vector3(-2.1, 5.0, -2.0),
		Vector3(2.3, 10.8, 1.9),
		Vector3(-2.0, 16.8, 2.0),
		Vector3(2.1, 22.6, -2.2),
		Vector3(-1.9, 28.8, 1.7),
		Vector3(1.4, 34.2, -1.6)
	]:
		_make_light(point, BLUE_ACCENT if point.x < 0.0 else ORANGE_ACCENT, 0.62, 5.5)

	_make_visual_box(Vector3(0.18, 32.0, 0.32), Vector3(-3.7, 18.0, 0.0), BLUE_ACCENT, decor_root, "CoreRailL", BLUE_ACCENT)
	_make_visual_box(Vector3(0.18, 32.0, 0.32), Vector3(3.7, 18.0, 0.0), ORANGE_ACCENT, decor_root, "CoreRailR", ORANGE_ACCENT)
	_make_visual_box(Vector3(0.32, 32.0, 0.18), Vector3(0.0, 18.0, -3.7), BLUE_ACCENT, decor_root, "CoreRailB", BLUE_ACCENT)
	_make_visual_box(Vector3(0.32, 32.0, 0.18), Vector3(0.0, 18.0, 3.7), GREEN_ACCENT, decor_root, "CoreRailF", GREEN_ACCENT)


func _make_energy_spiral(radius: float, color: Color, phase: float) -> void:
	for i in range(19):
		var angle := phase + float(i) * 0.61
		var y := 2.4 + float(i) * 1.82
		var position := Vector3(cos(angle) * radius, y, sin(angle) * radius)
		_make_visual_box(Vector3(0.36, 0.18, 0.92), position, color, decor_root, "SpiralNode", color)
		_make_light(position, color, 0.38, 3.4)


func _make_route_guides() -> void:
	var route_points := [
		Vector3(0.0, 1.0, 5.8),
		Vector3(-3.2, 6.2, 2.8),
		Vector3(3.6, 14.6, -0.4),
		Vector3(-2.8, 22.8, -3.0),
		Vector3(0.0, 31.2, 0.0)
	]

	for i in range(route_points.size() - 1):
		var color := BLUE_ACCENT if i % 2 == 0 else ORANGE_ACCENT
		_make_guide_segment(route_points[i], route_points[i + 1], color)


func _make_guide_segment(from: Vector3, to: Vector3, color: Color) -> void:
	var steps := 12
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var position := from.lerp(to, t)
		_make_visual_box(Vector3(0.24, 0.18, 0.24), position, color, decor_root, "GuideNode", color)
		if i % 2 == 0:
			_make_light(position + Vector3(0.0, 0.28, 0.0), color, 0.26, 2.6)


func _make_energy_gate(position: Vector3, color: Color, radius: float) -> void:
	_make_visual_box(Vector3(0.18, 2.8, 0.18), position + Vector3(-radius, 0.0, 0.0), color, decor_root, "GatePostL", color)
	_make_visual_box(Vector3(0.18, 2.8, 0.18), position + Vector3(radius, 0.0, 0.0), color, decor_root, "GatePostR", color)
	_make_visual_box(Vector3((radius * 2.0) + 0.1, 0.14, 0.18), position + Vector3(0.0, 1.35, 0.0), color, decor_root, "GateCap", color)
	_make_light(position + Vector3(0.0, 0.9, 0.0), color, 0.65, 4.8)


func _make_side_fins() -> void:
	for y in [6.0, 12.0, 18.0, 24.0, 30.0, 36.0]:
		_make_visual_box(Vector3(0.16, 2.6, 5.2), Vector3(-11.7, y, -6.4), BLUE_ACCENT, decor_root, "FinL", BLUE_ACCENT)
		_make_visual_box(Vector3(0.16, 2.6, 5.2), Vector3(-11.7, y, 6.4), BLUE_ACCENT, decor_root, "FinL", BLUE_ACCENT)
		_make_visual_box(Vector3(0.16, 2.6, 5.2), Vector3(11.7, y, -6.4), ORANGE_ACCENT, decor_root, "FinR", ORANGE_ACCENT)
		_make_visual_box(Vector3(0.16, 2.6, 5.2), Vector3(11.7, y, 6.4), ORANGE_ACCENT, decor_root, "FinR", ORANGE_ACCENT)

	for z in [-8.6, -3.0, 3.0, 8.6]:
		_make_visual_box(Vector3(8.0, 0.1, 0.16), Vector3(0.0, 1.0, z), BLUE_ACCENT if z < 0.0 else ORANGE_ACCENT, decor_root, "FloorGuide", BLUE_ACCENT if z < 0.0 else ORANGE_ACCENT)


func _make_crown_arch() -> void:
	_make_visual_box(Vector3(0.22, 4.2, 0.22), Vector3(-4.1, 33.2, 0.0), GREEN_ACCENT, decor_root, "CrownPillarL", GREEN_ACCENT)
	_make_visual_box(Vector3(0.22, 4.2, 0.22), Vector3(4.1, 33.2, 0.0), GREEN_ACCENT, decor_root, "CrownPillarR", GREEN_ACCENT)
	_make_visual_box(Vector3(8.4, 0.2, 0.22), Vector3(0.0, 35.1, 0.0), GREEN_ACCENT, decor_root, "CrownSpan", GREEN_ACCENT)
	_make_visual_box(Vector3(8.6, 0.08, 8.6), Vector3(0.0, 31.48, 0.0), GREEN_ACCENT, decor_root, "CrownPad", GREEN_ACCENT)
	_make_light(Vector3(0.0, 35.1, 0.0), GREEN_ACCENT, 1.25, 8.2)


func _make_reactor_halo(y: float, radius: float, color: Color) -> void:
	var mesh := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = 0.08
	mesh.mesh = cylinder
	mesh.material_override = _create_transparent_material(color, 0.22)
	mesh.position = Vector3(0.0, y, 0.0)
	decor_root.add_child(mesh)


func _make_energy_tube(position: Vector3, height: float, radius: float, color: Color, alpha: float) -> void:
	var mesh := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = height
	mesh.mesh = cylinder
	mesh.material_override = _create_transparent_material(color, alpha)
	mesh.position = position
	decor_root.add_child(mesh)


func _make_platform(size: Vector3, position: Vector3, accent: Color) -> void:
	_make_box(size, position, PLATFORM_COLOR, architecture_root, "Platform")
	_make_visual_box(Vector3(size.x - 0.26, 0.08, 0.18), position + Vector3(0, 0.24, -size.z * 0.5 + 0.12), accent, decor_root, "FrontEdge", accent)
	_make_visual_box(Vector3(size.x - 0.26, 0.08, 0.18), position + Vector3(0, 0.24, size.z * 0.5 - 0.12), accent, decor_root, "BackEdge", accent)
	_make_visual_box(Vector3(0.18, 0.08, size.z - 0.26), position + Vector3(-size.x * 0.5 + 0.12, 0.24, 0), accent, decor_root, "LeftEdge", accent)
	_make_visual_box(Vector3(0.18, 0.08, size.z - 0.26), position + Vector3(size.x * 0.5 - 0.12, 0.24, 0), accent, decor_root, "RightEdge", accent)


func _make_bridge(position: Vector3, size: Vector3, accent: Color) -> void:
	_make_box(size, position, Color(0.16, 0.2, 0.26), architecture_root, "Bridge")
	_make_visual_box(Vector3(size.x - 0.18, 0.06, maxf(0.14, size.z - 0.18)), position + Vector3(0.0, 0.16, 0.0), accent, decor_root, "BridgeStrip", accent)


func _spawn_ring(position: Vector3, scale_value: float) -> void:
	var ring := RING_SCENE.instantiate()
	ring.position = position
	ring.scale = Vector3.ONE * scale_value
	ring.ring_collected.connect(_on_ring_collected)
	gameplay_root.add_child(ring)


func _on_ring_collected(_ring: Area3D) -> void:
	rings_hit += 1
	GameState.repair_integrity(12.0)
	GameState.restore_energy(40.0)

	match rings_hit:
		1:
			respawn_transform = Transform3D(Basis.IDENTITY, Vector3(-4.2, 6.25, 3.9))
			GameState.set_objective("Anneau 1 / 3 valide. Montez maintenant vers la plateforme orange.")
			GameState.push_message("Premier anneau active : suivez les balises oranges vers la plateforme suivante.", 2.8)
		2:
			respawn_transform = Transform3D(Basis.IDENTITY, Vector3(4.4, 14.6, -0.2))
			GameState.set_objective("Anneau 2 / 3 valide. Continuez vers la plateforme bleue du reacteur.")
			GameState.push_message("Deuxieme anneau active : repartez vers la plateforme bleue plus haut.", 2.8)
		_:
			respawn_transform = Transform3D(Basis.IDENTITY, Vector3(0.0, 31.9, 0.0))
			GameState.set_objective("Reacteur stabilise. Posez-vous maintenant sur la couronne verte du sommet.")
			GameState.push_message("Tous les anneaux sont actifs : allez tout en haut sur la couronne verte.", 3.0)


func _on_finish_entered(_body: Node) -> void:
	if rings_hit >= REQUIRED_RINGS:
		GameState.complete_level()
	else:
		GameState.push_message("Il faut encore activer les anneaux du reacteur.")


func _on_ship_body_entered(body: Node) -> void:
	if collision_cooldown > 0.0:
		return
	if body.is_in_group("hazard_obstacle"):
		collision_cooldown = 0.8
		GameState.damage_integrity(6.0, "Collision avec une structure instable du reacteur.")


func _respawn_ship(apply_penalty: bool) -> void:
	if apply_penalty:
		GameState.apply_fall_penalty()
		GameState.damage_integrity(2.0, "Le propulseur a quitte la trajectoire.")
		if GameState.integrity <= 0.0:
			return

	ship_body.global_transform = respawn_transform
	ship_body.linear_velocity = Vector3.ZERO
	ship_body.angular_velocity = Vector3.ZERO
	ship_body.sleeping = false
	GameState.restore_energy(20.0)
	_snap_ship_camera()


func _snap_ship_camera() -> void:
	var ship_camera := ship_root.get_node_or_null("ship_cam")
	if ship_camera != null and ship_camera.has_method("snap_to_target"):
		ship_camera.snap_to_target()


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


func _create_material(color: Color, emission_color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	if emission_color != Color(0, 0, 0, 1):
		material.emission_enabled = true
		material.emission = emission_color
	return material


func _create_transparent_material(color: Color, alpha: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(color.r, color.g, color.b, alpha)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.emission_enabled = true
	material.emission = color
	material.roughness = 0.1
	return material


func _make_light(position: Vector3, color: Color, energy: float, range_value: float) -> void:
	var light := OmniLight3D.new()
	light.position = position
	light.light_color = color
	light.light_energy = energy
	light.omni_range = range_value
	light_root.add_child(light)
