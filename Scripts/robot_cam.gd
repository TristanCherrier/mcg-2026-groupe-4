extends Node3D

@export
var Head : Node3D
@export
var Head2 : Node3D
@export
var Cam : Node3D

var rotY : float
var rotX : float
var smooth_rotY : float
var smooth_rotX : float
var zoom_offset : float = 1
var smooth_zoom_offset : float = 1
var zoom_step : float = 0.5
var mouse_motion : Vector2
var rotY_offset : float

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(delta: float) -> void:
	rotY = mouse_motion.x /50
	rotX = mouse_motion.y /50
	mouse_motion = Vector2.ZERO
	smooth_rotY = lerpf(smooth_rotY, rotY, 20 * delta)
	smooth_rotX = lerpf(smooth_rotX, rotX, 20 * delta)
	rotate_y(-smooth_rotY)
	var quat_rot = quaternion.from_euler(rotation)
	var head_quat_rot = quaternion.from_euler(Head.rotation)
	head_quat_rot = head_quat_rot.slerp(quat_rot, 10 * delta)
	Head.rotation = head_quat_rot.get_euler()
	#rotY_offset = Head.rotation.signed_angle_to(rotation, Vector3.UP)
	#Head.rotation_degrees.y = rotY_offset * 10 * delta
	$cam_subNode.rotate_object_local(Vector3.RIGHT,-smooth_rotX)
	$cam_subNode.rotation_degrees.x = min(80,max(-60, $cam_subNode.rotation_degrees.x))
	Head2.rotation.x = lerpf(Head2.rotation.x, $cam_subNode.rotation.x, 10 * delta)
	Head2.rotation_degrees.x = min(80,max(-2, Head2.rotation_degrees.x))
	rotY = 0
	rotX = 0
	
	if Input.is_action_just_pressed("Zoom_In"):
		zoom_offset -= zoom_step
	if Input.is_action_just_pressed("Zoom_Out"):
		zoom_offset += zoom_step
	zoom_offset = clampf(zoom_offset, 0, 3)
	smooth_zoom_offset = lerpf(smooth_zoom_offset, zoom_offset, 10 * delta)
	Cam.position.z = smooth_zoom_offset

func _input(event):
	if event is InputEventMouseMotion:
		mouse_motion += event.relative
