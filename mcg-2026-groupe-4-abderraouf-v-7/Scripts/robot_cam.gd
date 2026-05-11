# robot_cam.gd – Caméra robot avec SpringArm3D
#
# Hiérarchie attendue dans robot.tscn :
#
#   body_rb  (RigidBody3D)
#   └── cam_node  (Node3D)            ← ce nœud (script attaché ici)
#       └── SpringArm3D               ← spring_length variable (zoom)
#           └── robot_cam  (Camera3D) ← current = true
#               └── InteractRay  (RayCast3D)

extends Node3D

@export var Head:  Node3D
@export var Head2: Node3D
@export var Cam:   Node3D   # la Camera3D (robot_cam)

var rotY := 0.0
var rotX := 0.0
var smooth_rotY := 0.0
var smooth_rotX := 0.0
var zoom_offset        := 1.6
var smooth_zoom_offset := 1.6
const ZOOM_STEP  := 0.5
const ZOOM_MIN   := 0.0
const ZOOM_MAX   := 3.0
var mouse_motion := Vector2.ZERO
var third_person := true

# Référence au SpringArm3D enfant direct
@onready var _spring_arm: SpringArm3D = $SpringArm3D


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_spring_arm.spring_length = zoom_offset


func _process(delta: float) -> void:
	rotY = mouse_motion.x / 50.0
	rotX = mouse_motion.y / 50.0
	mouse_motion = Vector2.ZERO

	smooth_rotY = lerpf(smooth_rotY, rotY, 20.0 * delta)
	smooth_rotX = lerpf(smooth_rotX, rotX, 20.0 * delta)

	rotate_y(-smooth_rotY)

	# Inclinaison tête horizontale
	var quat_rot      := Quaternion.from_euler(rotation)
	var head_quat_rot := Quaternion.from_euler(Head.rotation)
	head_quat_rot = head_quat_rot.slerp(quat_rot, 10.0 * delta)
	Head.rotation = head_quat_rot.get_euler()

	# Pitch du SpringArm (montée/descente caméra)
	_spring_arm.rotate_object_local(Vector3.RIGHT, -smooth_rotX)
	_spring_arm.rotation_degrees.x = clampf(_spring_arm.rotation_degrees.x, -60.0, 80.0)

	# Inclinaison tête verticale
	Head2.rotation.x = lerpf(Head2.rotation.x, _spring_arm.rotation.x, 10.0 * delta)
	Head2.rotation_degrees.x = clampf(Head2.rotation_degrees.x, -2.0, 80.0)

	rotY = 0.0
	rotX = 0.0

	# Zoom
	if InputMap.has_action("Zoom_In") and Input.is_action_just_pressed("Zoom_In"):
		zoom_offset -= ZOOM_STEP
	if InputMap.has_action("Zoom_Out") and Input.is_action_just_pressed("Zoom_Out"):
		zoom_offset += ZOOM_STEP
	if Input.is_action_just_pressed("toggle_view"):
		third_person = not third_person
		zoom_offset = 1.6 if third_person else 0.0

	zoom_offset = clampf(zoom_offset, ZOOM_MIN, ZOOM_MAX)
	smooth_zoom_offset = lerpf(smooth_zoom_offset, zoom_offset, 10.0 * delta)

	# SpringArm gère les collisions ET le zoom
	_spring_arm.spring_length = smooth_zoom_offset

	# Cache le corps du robot en vue FPS
	if Head != null:
		Head.get_parent_node_3d().visible = smooth_zoom_offset >= 0.25

	_update_prompt()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_motion += (event as InputEventMouseMotion).relative


func _update_prompt() -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud == null or not hud.has_method("set_prompt"):
		return

	if Cam == null:
		hud.set_prompt("")
		return

	var interact_ray := Cam.get_node_or_null("InteractRay") as RayCast3D
	if interact_ray == null:
		hud.set_prompt("")
		return

	if interact_ray.is_colliding():
		var collider := interact_ray.get_collider()
		if collider != null and collider.has_method("get_interaction_text"):
			hud.set_prompt(collider.get_interaction_text())
			if Input.is_action_just_pressed("interact") and collider.has_method("interact"):
				collider.interact(get_parent())
			return
	hud.set_prompt("")
