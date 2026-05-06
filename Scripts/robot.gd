extends RigidBody3D

@export
var CamNode : Node3D

var going : bool

func _ready() -> void:
	pass

func _integrate_forces(_state: PhysicsDirectBodyState3D) -> void:
	going = false
	if Input.is_action_pressed("Roll_Forward"):
		apply_torque(-CamNode.global_basis.x * (angular_damp + 1))
		going = true
	if Input.is_action_pressed("Roll_Back"):
		apply_torque(CamNode.global_basis.x * (angular_damp + 1))
		going = true
	if Input.is_action_pressed("Roll_Left"):
		apply_torque(CamNode.global_basis.z * (angular_damp + 1))
		going = true
	if Input.is_action_pressed("Roll_Right"):
		apply_torque(-CamNode.global_basis.z * (angular_damp + 1))
		going = true
		
	if going:
		lock_rotation = false
	else:
		lock_rotation = true
