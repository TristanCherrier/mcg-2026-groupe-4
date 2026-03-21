extends RigidBody3D

@export
var CamNode : Node3D

func _ready() -> void:
	pass # Replace with function body.

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if Input.is_action_pressed("Roll_Forward"):
		apply_torque(-CamNode.global_basis.x * (angular_damp + 1))
	if Input.is_action_pressed("Roll_Back"):
		apply_torque(CamNode.global_basis.x * (angular_damp + 1))
	if Input.is_action_pressed("Roll_Left"):
		apply_torque(CamNode.global_basis.z * (angular_damp + 1))
	if Input.is_action_pressed("Roll_Right"):
		apply_torque(-CamNode.global_basis.z * (angular_damp + 1))
