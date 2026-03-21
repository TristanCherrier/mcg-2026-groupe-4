extends Camera3D

@export
var ship : Node3D
@export
var target : Node3D

var rotY : float
var rotX : float


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(delta: float) -> void:
	target.global_position = ship.global_position + ship.global_basis.y * 0.6 + ship.global_basis.z * 0.8
	target.look_at(ship.global_position - ship.global_basis.z * 20, ship.global_basis.y)
	
	global_position = global_position.lerp(target.global_position, 30 * delta)

	var target_quat = Quaternion(target.basis.orthonormalized())
	var cam_quat = Quaternion(basis)
	cam_quat = cam_quat.normalized().slerp(target_quat.normalized(), 50 * delta)
	basis = Basis(cam_quat)
