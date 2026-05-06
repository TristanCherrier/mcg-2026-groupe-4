extends Camera3D

@export
var car_rb : Node3D
@export
var target : Node3D

var rotY : float
var rotX : float


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	snap_to_target()

func _process(delta: float) -> void:
	_update_target()
	
	global_position = global_position.lerp(target.global_position, 6.5 * delta)

	var target_quat = Quaternion(target.basis.orthonormalized())
	var cam_quat = Quaternion(basis)
	cam_quat = cam_quat.normalized().slerp(target_quat.normalized(), 7.5 * delta)
	basis = Basis(cam_quat)


func snap_to_target() -> void:
	_update_target()
	global_position = target.global_position
	basis = target.basis


func _update_target() -> void:
	target.global_position = car_rb.global_position + Vector3.UP * 2.7 + car_rb.global_basis.z * 7.0
	target.look_at(car_rb.global_position + Vector3.UP * 0.75 - car_rb.global_basis.z * 17.0, Vector3.UP)
