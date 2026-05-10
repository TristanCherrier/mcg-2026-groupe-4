# car_cam.gd – Caméra 3ème personne voiture avec SpringArm3D
#
# Hiérarchie attendue dans "Tiny Car.tscn" :
#
#   Car  (Node3D)
#   ├── CarRB  (RigidBody3D)
#   │   └── cam_target  (Node3D)
#   └── cam_pivot  (Node3D)        ← ce nœud (script attaché ici)
#       └── SpringArm3D            ← spring_length = 9.0, margin = 0.3
#           └── Camera3D           ← current = true, fov = 70.0

extends Node3D

@export var car_rb: Node3D
@export var target: Node3D
@export var spring_arm: SpringArm3D
@export var camera: Camera3D

const START_FORWARD      := Vector3(0.0, 0.0, -1.0)
const INTRO_DURATION     := 1.2
const DRIVE_HEIGHT       := 3.0
const DRIVE_DISTANCE     := 9.0
const MIN_LOOK_AHEAD     := 18.0
const MAX_LOOK_AHEAD     := 26.0
const CAM_ROTATION_SPEED := 0.35

var intro_timer  := INTRO_DURATION
var intro_locked := true
var _smooth_forward := START_FORWARD


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if spring_arm != null:
		spring_arm.spring_length = DRIVE_DISTANCE
	if camera != null:
		camera.fov = 70.0
	snap_to_target()


func _process(delta: float) -> void:
	if car_rb == null or spring_arm == null or camera == null:
		return

	var speed := _get_speed()
	intro_timer = maxf(0.0, intro_timer - delta)

	if intro_locked and intro_timer > 0.0 and speed < 1.0:
		_apply_intro_view(delta)
		return

	intro_locked = false
	_apply_drive_view(delta, speed)


func snap_to_target() -> void:
	if car_rb == null:
		return
	intro_timer  = INTRO_DURATION
	intro_locked = true
	_smooth_forward = START_FORWARD

	# Positionne le pivot derrière la voiture, caméra dans l'axe du SpringArm
	var desired_pivot := car_rb.global_position + Vector3(0.9, 2.9, 8.6)
	global_position = desired_pivot
	rotation        = Vector3.ZERO

	if target != null:
		target.global_position = car_rb.global_position + Vector3.UP * 1.0

	if camera != null and target != null:
		camera.look_at(car_rb.global_position + Vector3(0.0, 1.0, -22.0), Vector3.UP)


func _apply_intro_view(delta: float) -> void:
	var desired_pivot := car_rb.global_position + Vector3(0.9, 2.9, 8.6)
	global_position = global_position.lerp(desired_pivot, minf(1.0, delta * 6.5))

	if target != null:
		var focus := car_rb.global_position + Vector3.UP * 1.0
		target.global_position = target.global_position.lerp(focus, minf(1.0, delta * 7.0))

	if camera != null and target != null:
		camera.look_at(car_rb.global_position + Vector3(0.0, 1.0, -22.0), Vector3.UP)


func _apply_drive_view(delta: float, speed: float) -> void:
	var actual_forward := _get_actual_forward(speed)
	_smooth_forward = _smooth_forward.lerp(actual_forward, minf(1.0, delta * CAM_ROTATION_SPEED))
	if _smooth_forward.length_squared() > 0.001:
		_smooth_forward = _smooth_forward.normalized()

	var backward  := -_smooth_forward
	var right     := _smooth_forward.cross(Vector3.UP).normalized()
	var look_ahead := clampf(MIN_LOOK_AHEAD + speed * 0.35, MIN_LOOK_AHEAD, MAX_LOOK_AHEAD)
	var focus     := car_rb.global_position + Vector3.UP * 1.0

	# Le pivot se place derrière et au-dessus ; le SpringArm gère les collisions
	var desired_pivot := focus + backward * 1.0 + Vector3.UP * DRIVE_HEIGHT + right * 0.3
	global_position = global_position.lerp(desired_pivot, minf(1.0, delta * 3.5))

	# Oriente le pivot pour que le SpringArm pointe vers l'avant (caméra derrière)
	var look_target := focus + _smooth_forward * look_ahead + Vector3.UP * 0.45
	if target != null:
		target.global_position = target.global_position.lerp(focus, minf(1.0, delta * 6.0))

	if camera != null and target != null:
		camera.look_at(look_target, Vector3.UP)


func _get_speed() -> float:
	if car_rb is RigidBody3D:
		return (car_rb as RigidBody3D).linear_velocity.length()
	return 0.0


func _get_actual_forward(speed: float) -> Vector3:
	if speed < 0.35:
		return START_FORWARD
	var basis_forward := -car_rb.global_basis.z
	if basis_forward.length_squared() < 0.001:
		return START_FORWARD
	return basis_forward.normalized()
