extends CharacterBody3D

const SPEED = 6.0
const SPRINT_SPEED = 10.0
const JETPACK_FORCE = 12.0
const MOUSE_SENSITIVITY = 0.003
const FALL_LIMIT = -5.0

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var fuel: float = 100.0
var jetpack_active := false

func _ready() -> void:
	add_to_group("player")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

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

	jetpack_active = Input.is_action_pressed("ui_accept") and fuel > 0.0

	if jetpack_active:
		velocity.y = JETPACK_FORCE
		fuel = max(0.0, fuel - 30.0 * delta)
	else:
		if not is_on_floor():
			velocity.y -= gravity * delta
		if is_on_floor():
			fuel = min(100.0, fuel + 20.0 * delta)

	var sprinting := Input.is_action_pressed("ui_page_up") or Input.is_key_pressed(KEY_SHIFT)
	var current_speed := SPRINT_SPEED if sprinting else SPEED

	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, current_speed)
		velocity.z = move_toward(velocity.z, 0.0, current_speed)

	move_and_slide()
