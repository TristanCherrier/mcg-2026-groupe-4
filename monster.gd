extends CharacterBody3D

@export
var Player : Node3D
@export
var animationPlayer : AnimationPlayer
@export
var base_speed : float  = 200
var speed : float = 200
var acceleration : float = 80
var attacking : bool = false
var whish_velocity : Vector3 = Vector3.ZERO
var previous_velocity : Vector3 = Vector3.ZERO
var turn_rate : float = 5

func _ready() -> void:
	speed = base_speed
	animationPlayer.play("ani_monster_run")

func _physics_process(delta: float) -> void:
	if attacking:
		velocity -= velocity * 3 * delta
		turn_rate = 2
	else:
		speed += acceleration * delta
		animationPlayer.speed_scale = (speed / base_speed) / scale.x
		turn_rate = 3
	whish_velocity = Player.global_position - global_position
	whish_velocity.y = 0
	whish_velocity = whish_velocity.normalized() * speed * delta
	velocity = previous_velocity.slerp(whish_velocity, turn_rate * delta)
	previous_velocity = velocity
	look_at(global_position + velocity)
	move_and_slide()

func prepare_attack():
	speed = 50
	attacking = true
	animationPlayer.speed_scale = 1
	animationPlayer.play("ani_monster_chomp")
	Utils.schedule(self, "try_attack", 0.5)

func try_attack():
	if $chomp_node.get_overlapping_bodies().size() > 0:
		GameState.set_integrity(GameState.integrity - 10)
		GameState.add_points(-20)

func _on_chomp_node_body_entered(_body: Node3D) -> void:
	if not attacking:
		prepare_attack()

func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	attacking = false
	if $chomp_node.get_overlapping_bodies().size() > 0:
		prepare_attack()
	else:
		speed = base_speed
		animationPlayer.speed_scale = 1 / scale.x
		animationPlayer.play("ani_monster_run")
