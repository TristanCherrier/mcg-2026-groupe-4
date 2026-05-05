extends CharacterBody3D

const SPEED = 8.0
const TURN_SPEED = 2.0
const FALL_LIMIT = -5.0

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
	add_to_group("player")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _physics_process(delta: float) -> void:
	# Chute = retour niveau 1
	if global_position.y < FALL_LIMIT and not GameManager.game_over:
		GameManager.trigger_game_over()
		return

	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_pressed("ui_left"):
		rotate_y(TURN_SPEED * delta)
	if Input.is_action_pressed("ui_right"):
		rotate_y(-TURN_SPEED * delta)

	var throttle := 0.0
	if Input.is_action_pressed("ui_up"):
		throttle = 1.0
	elif Input.is_action_pressed("ui_down"):
		throttle = -0.5

	var forward := -transform.basis.z * SPEED * throttle
	velocity.x = forward.x
	velocity.z = forward.z

	move_and_slide()
