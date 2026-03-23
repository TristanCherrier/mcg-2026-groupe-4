extends Node3D

@export
var Head : Node3D
@export
var Head2 : Node3D

var rotY : float
var rotX : float
var smooth_rotY : float
var smooth_rotX : float
var smoother_rotY : float
var smoother_rotX : float
var mouse_motion : Vector2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	#Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	rotY = mouse_motion.x /50
	rotX = mouse_motion.y /50
	mouse_motion = Vector2.ZERO
	smooth_rotY = lerpf(smooth_rotY, rotY, 0.3)
	smooth_rotX = lerpf(smooth_rotX, rotX, 0.3)
	smoother_rotY = lerpf(smoother_rotY, rotY, 0.1)
	rotate_y(-smooth_rotY)
	Head.rotate_y(-smoother_rotY)
	$cam_subNode.rotate_object_local(Vector3.RIGHT,-smooth_rotX)
	$cam_subNode.rotation_degrees.x = min(80,max(-60, $cam_subNode.rotation_degrees.x))
	Head2.rotation_degrees.x = lerpf(Head2.rotation_degrees.x, $cam_subNode.rotation_degrees.x, 0.1)
	Head2.rotation_degrees.x = min(80,max(-2, Head2.rotation_degrees.x))
	rotY = 0
	rotX = 0

func _input(event):
	if event is InputEventMouseMotion:
		mouse_motion += event.relative
