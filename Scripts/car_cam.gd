extends Camera3D

@export
var car_body : RigidBody3D
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
	look_at(target_X.global_position)
	fov = 75 + car_body.get_LocalVelocity().z

func _input(event):
	if event is InputEventMouseMotion:
		mouse_motion += event.relative
