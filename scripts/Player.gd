extends CharacterBody3D

const SPEED = 5.0
const SPRINT_SPEED = 9.0
const JUMP_VELOCITY = 5.5
const MOUSE_SENSITIVITY = 0.003
const FALL_LIMIT = -5.0

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _sprint_label: Label = null

func _ready() -> void:
	add_to_group("player")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# Ajoute un label discret pour indiquer le sprint
	_sprint_label = Label.new()
	_sprint_label.text = "[ SPRINT ]"
	_sprint_label.add_theme_font_size_override("font_size", 16)
	_sprint_label.modulate = Color(1.0, 0.8, 0.2, 0.9)
	_sprint_label.visible = false
	var canvas := CanvasLayer.new()
	canvas.layer = 5
	canvas.add_child(_sprint_label)
	_sprint_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_sprint_label.offset_top = -60.0
	add_child(canvas)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		var cam_arm := get_node_or_null("CamArm")
		if cam_arm:
			cam_arm.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
			cam_arm.rotation.x = clamp(cam_arm.rotation.x, -PI / 3.0, PI / 3.0)
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _physics_process(delta: float) -> void:
	if global_position.y < FALL_LIMIT and not GameManager.game_over:
		GameManager.trigger_game_over()
		return

	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var sprinting := Input.is_action_pressed("ui_page_up") or Input.is_key_pressed(KEY_SHIFT)
	var current_speed := SPRINT_SPEED if sprinting else SPEED
	if _sprint_label:
		_sprint_label.visible = sprinting

	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, current_speed)
		velocity.z = move_toward(velocity.z, 0.0, current_speed)

	move_and_slide()
