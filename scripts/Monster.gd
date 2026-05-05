extends CharacterBody3D

const SPEED_BASE = 2.5
const DAMAGE_COOLDOWN = 1.5
# Le monstre est plus rapide au niveau 2 et 3
var speed: float = SPEED_BASE

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var player: Node3D = null
var damage_timer: float = 0.0

func _ready() -> void:
	add_to_group("monster")
	speed = SPEED_BASE + (GameManager.current_level - 1) * 0.8

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	damage_timer -= delta

	if player == null:
		player = get_tree().get_first_node_in_group("player")
		return

	var dir := (player.global_position - global_position).normalized()
	dir.y = 0.0
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed

	move_and_slide()

	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		if col.get_collider() == player and damage_timer <= 0.0:
			damage_timer = DAMAGE_COOLDOWN
			GameManager.lose_score(10)
			var hud := get_tree().get_first_node_in_group("hud")
			if hud and hud.has_method("show_message"):
				hud.show_message("-10 points !", 1.0)
