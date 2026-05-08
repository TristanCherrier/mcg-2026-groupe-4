extends Camera3D

@export
var car_rb : Node3D
@export
var target_Y : Node3D
@export
var target_X : Node3D

var rotX : float
var rotY : float
var smooth_rotX : float
var smooth_rotY : float
var mouse_motion : Vector2

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(delta: float) -> void:
	rotX = mouse_motion.y / 400
	rotY = mouse_motion.x / 400
	mouse_motion = Vector2.ZERO
	smooth_rotX = lerpf(smooth_rotX, rotX, 10 * delta)
	smooth_rotY = lerpf(smooth_rotY, rotY, 10 * delta)
	target_Y.rotate_y(-smooth_rotY)
	target_X.rotate_x(smooth_rotX)
	target_X.rotation_degrees.x = min(80,max(-15, target_X.rotation_degrees.x))
	
	#target.global_position = car_rb.global_position + car_rb.global_basis.y * 1 + car_rb.global_basis.z * 3.5
	look_at(target_X.global_position)
	
	global_position = (target_X.global_position + target_X.global_basis.y * 0.1 + -target_X.global_basis.z * 3.5)

	#var target_quat = Quaternion(target.basis.orthonormalized())
	#var cam_quat = Quaternion(basis)
	#cam_quat = cam_quat.normalized().slerp(target_quat.normalized(), 50 * delta)
	#basis = Basis(cam_quat)

func _input(event):
	if event is InputEventMouseMotion:
		mouse_motion += event.relative
