extends Camera3D

@export
var car_rb : Node3D
@export
var target : Node3D

var rotY : float
var smooth_rotY : float
var mouse_motion : Vector2


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(delta: float) -> void:
	rotY = mouse_motion.x / 400
	mouse_motion = Vector2.ZERO
	smooth_rotY = lerpf(smooth_rotY, rotY, 5 * delta)
	target.rotate_y(-smooth_rotY)
	
	#target.global_position = car_rb.global_position + car_rb.global_basis.y * 1 + car_rb.global_basis.z * 3.5
	look_at(target.global_position)
	
	global_position = (target.global_position + target.global_basis.y * 0.1 + target.global_basis.z * 3.5)

	#var target_quat = Quaternion(target.basis.orthonormalized())
	#var cam_quat = Quaternion(basis)
	#cam_quat = cam_quat.normalized().slerp(target_quat.normalized(), 50 * delta)
	#basis = Basis(cam_quat)

func _input(event):
	if event is InputEventMouseMotion:
		mouse_motion += event.relative
