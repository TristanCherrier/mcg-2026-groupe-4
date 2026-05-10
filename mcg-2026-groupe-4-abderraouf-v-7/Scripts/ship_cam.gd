# ship_cam.gd  –  Caméra 3ème personne avec SpringArm3D
#
# Hiérarchie attendue dans ship.tscn :
#
#   Ship  (Node3D)
#   ├── ship_rb  (RigidBody3D)          ← vaisseau
#   ├── cam_pivot  (Node3D)             ← ce nœud (script attaché ici)
#   │   └── SpringArm3D                 ← détecte les collisions caméra-mur
#   │       └── Camera3D               ← la vraie caméra
#   └── cam_target  (Node3D)           ← point cible du look_at

extends Node3D

# ── Références de scène ────────────────────────────────────────────────────
@export var ship_rb:    RigidBody3D
@export var target:     Node3D
@export var spring_arm: SpringArm3D
@export var camera:     Camera3D

# ── Paramètres caméra ─────────────────────────────────────────────────────
@export var spring_length  := 8.0    # distance caméra-pivot au repos
@export var follow_height  := 1.8    # hauteur du pivot au-dessus du vaisseau
@export var focus_height   := 1.55   # hauteur du point cible
@export var lead_amount    := 0.2    # anticipation sur la vélocité
@export var base_fov       := 76.0
@export var max_fov_boost  := 8.0

# ── Contrôle souris (yaw + pitch indépendants du vaisseau) ────────────────
@export var mouse_sensitivity := 0.003
@export var pitch_min_deg     := -60.0
@export var pitch_max_deg     :=  75.0

# ── Lissage ────────────────────────────────────────────────────────────────
@export var pos_smooth   := 7.2
@export var focus_smooth := 7.2

# ── État interne ───────────────────────────────────────────────────────────
var _yaw   := 0.0
var _pitch := 0.0


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if spring_arm != null:
		spring_arm.spring_length = spring_length
	if ship_rb != null:
		_yaw   = ship_rb.rotation.y
		_pitch = ship_rb.rotation.x
	call_deferred("_snap_to_ship")


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		_yaw   -= motion.relative.x * mouse_sensitivity
		_pitch -= motion.relative.y * mouse_sensitivity
		_pitch  = clampf(_pitch,
			deg_to_rad(pitch_min_deg),
			deg_to_rad(pitch_max_deg))


func _process(delta: float) -> void:
	if ship_rb == null or spring_arm == null or camera == null:
		return

	# 1. Suit la position du vaisseau
	var desired_pivot := ship_rb.global_position + Vector3.UP * follow_height
	global_position = global_position.lerp(desired_pivot,
		clampf(delta * pos_smooth, 0.0, 1.0))

	# 2. Applique yaw + pitch au pivot
	#    Le SpringArm enfant pointe automatiquement dans -Z local → caméra en arrière
	rotation = Vector3(_pitch, _yaw, 0.0)

	# 3. Le SpringArm raccourcit tout seul en cas de collision : rien à faire ici.

	# 4. Oriente la caméra vers le point cible
	var desired_focus := _compute_focus()
	if target != null:
		target.global_position = target.global_position.lerp(
			desired_focus, clampf(delta * focus_smooth, 0.0, 1.0))
		camera.look_at(target.global_position, Vector3.UP)

	# 5. FOV dynamique
	var speed := ship_rb.linear_velocity.length()
	camera.fov = lerpf(camera.fov,
		base_fov + minf(speed * 0.35, max_fov_boost),
		clampf(delta * 3.2, 0.0, 1.0))


func _compute_focus() -> Vector3:
	var velocity := ship_rb.linear_velocity
	var look_dir := -ship_rb.global_basis.z
	return ship_rb.global_position \
		+ Vector3.UP * focus_height \
		+ velocity * lead_amount \
		+ look_dir * 4.0


func _snap_to_ship() -> void:
	if ship_rb == null:
		return
	global_position = ship_rb.global_position + Vector3.UP * follow_height
	rotation = Vector3(_pitch, _yaw, 0.0)
	if target != null:
		target.global_position = _compute_focus()
	if camera != null:
		var speed := ship_rb.linear_velocity.length()
		camera.fov = base_fov + minf(speed * 0.35, max_fov_boost)
		if target != null:
			camera.look_at(target.global_position, Vector3.UP)
