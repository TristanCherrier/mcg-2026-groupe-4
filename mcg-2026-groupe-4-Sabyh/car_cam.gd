extends Camera3D

@export var car_rb: Node3D
@export var target: Node3D

const START_FORWARD := Vector3(0.0, 0.0, -1.0)
const INTRO_DURATION := 1.2
const INTRO_POSITION_OFFSET := Vector3(0.9, 2.9, 8.6)
const INTRO_LOOK_OFFSET := Vector3(0.0, 1.0, -22.0)
const DRIVE_HEIGHT := 3.0
const DRIVE_DISTANCE := 9.0
const DRIVE_SIDE_OFFSET := 0.8
const MIN_LOOK_AHEAD := 18.0
const MAX_LOOK_AHEAD := 26.0

var intro_timer := INTRO_DURATION
var intro_locked := true


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	fov = 70.0
	snap_to_target()


func _process(delta: float) -> void:
	if car_rb == null:
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

	intro_timer = INTRO_DURATION
	intro_locked = true
	var focus := car_rb.global_position + Vector3.UP * 1.0
	var desired_position := car_rb.global_position + INTRO_POSITION_OFFSET
	var desired_target := car_rb.global_position + INTRO_LOOK_OFFSET

	global_position = desired_position
	look_at(desired_target, Vector3.UP)

	if target != null:
		target.global_position = focus
		target.look_at(desired_target, Vector3.UP)


func _apply_intro_view(delta: float) -> void:
	var focus := car_rb.global_position + Vector3.UP * 1.0
	var desired_position := car_rb.global_position + INTRO_POSITION_OFFSET
	var desired_target := car_rb.global_position + INTRO_LOOK_OFFSET

	global_position = global_position.lerp(desired_position, minf(1.0, delta * 6.5))
	look_at(desired_target, Vector3.UP)

	if target != null:
		target.global_position = target.global_position.lerp(focus, minf(1.0, delta * 7.0))
		target.look_at(desired_target, Vector3.UP)


func _apply_drive_view(delta: float, speed: float) -> void:
	var forward := _get_forward_direction(speed)
	var backward := -forward
	var right := forward.cross(Vector3.UP).normalized()
	var look_ahead := clampf(MIN_LOOK_AHEAD + speed * 0.35, MIN_LOOK_AHEAD, MAX_LOOK_AHEAD)
	var focus := car_rb.global_position + Vector3.UP * 1.0
	var desired_position := focus + backward * DRIVE_DISTANCE + Vector3.UP * DRIVE_HEIGHT + right * DRIVE_SIDE_OFFSET
	var desired_target := focus + forward * look_ahead + Vector3.UP * 0.45

	global_position = global_position.lerp(desired_position, minf(1.0, delta * 4.8))
	look_at(desired_target, Vector3.UP)

	if target != null:
		target.global_position = target.global_position.lerp(focus, minf(1.0, delta * 6.0))
		target.look_at(desired_target, Vector3.UP)


func _get_speed() -> float:
	if car_rb is RigidBody3D:
		return (car_rb as RigidBody3D).linear_velocity.length()
	return 0.0


func _get_forward_direction(speed: float) -> Vector3:
	if speed < 0.35:
		return START_FORWARD

	var basis_forward := -car_rb.global_basis.z
	if basis_forward.length_squared() < 0.001:
		return START_FORWARD
	return basis_forward.normalized()
