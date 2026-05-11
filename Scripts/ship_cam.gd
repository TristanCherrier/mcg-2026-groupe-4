extends Camera3D

@export
var ship_body : Node3D
@export
var target : Node3D
@export
var back_target : Node3D
@export
var back_cam : Camera3D
var subViewport : SubViewport
@export
var back_sprite : Sprite2D

var rotY : float
var rotX : float


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	global_position = global_position.lerp(target.global_position, 30 * delta)
	back_cam.global_position = back_target.global_position
	back_cam.global_rotation = back_target.global_rotation
	back_cam.rotate_object_local(Vector3.UP, PI)
	var ship_quat = Quaternion(ship_body.basis.orthonormalized())
	var cam_quat = Quaternion(basis)
	cam_quat = cam_quat.normalized().slerp(ship_quat.normalized(), 50 * delta)
	basis = Basis(cam_quat)
	fov = 75 + pow(ship_body.get_LocalVelocity().z / 10, 2)
