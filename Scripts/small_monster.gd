extends RigidBody3D

@export
var speed : float = 1
var cooldown_timer: float = 0.0
var score_penalty: int = 50
var damage_cooldown: float = 1.5
var playerTarget : Node3D
@export
var animation_player : AnimationPlayer 

func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 5
	if playerTarget != null:
		speed = randf_range(0.8,1.2);
		animation_player.play("ani_ptitmonstre_gnaw", -1, speed)
	
func _physics_process(delta: float) -> void:
	cooldown_timer = maxf(cooldown_timer - delta, 0.0)
	if playerTarget != null:
		look_at(playerTarget.global_position)
		apply_central_force(-global_basis.z * speed * 500 * delta)

func try_damage() -> void:
	if cooldown_timer > 0.0:
		return
	cooldown_timer = damage_cooldown
	GameState.add_points(-score_penalty)

func _on_body_entered(body: Node) -> void:
	if body.name == playerTarget.get_parent().get_parent().name:
		try_damage()
		queue_free()
