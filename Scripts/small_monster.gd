extends RigidBody3D

@export
var speed : float = 1
var playerTarget : Node3D
@export
var animation_player : AnimationPlayer 

func _ready() -> void:
	if playerTarget != null:
		speed = randf_range(0.8,1.2);
		animation_player.play("ani_ptitmonstre_gnaw", -1, speed)
	
func _physics_process(delta: float) -> void:
	if playerTarget != null:
		look_at(playerTarget.global_position)
		apply_central_force(-global_basis.z * speed * 500 * delta)
