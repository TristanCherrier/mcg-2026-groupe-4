extends RigidBody3D

signal fell

@export
var CamNode : Node3D
@export
var speed_scale : float = 0.3
var going : bool
var respawn_lock = false
var respawn_safe_time = 0.0

func _ready() -> void:
	add_to_group("foot_player")
	var robot_root = get_parent()
	if robot_root != null:
		robot_root.add_to_group("foot_player")
		var body_rb = robot_root.get_node_or_null("body_rb") as RigidBody3D
		if body_rb != null:
			body_rb.add_to_group("foot_player")

func _integrate_forces(_state: PhysicsDirectBodyState3D) -> void:
	going = false
	if Input.is_action_pressed("Roll_Forward"):
		apply_torque(-CamNode.global_basis.x * (angular_damp * speed_scale + 1))
		going = true
	if Input.is_action_pressed("Roll_Back"):
		apply_torque(CamNode.global_basis.x * (angular_damp * speed_scale + 1))
		going = true
	if Input.is_action_pressed("Roll_Left"):
		apply_torque(CamNode.global_basis.z * (angular_damp * speed_scale + 1))
		going = true
	if Input.is_action_pressed("Roll_Right"):
		apply_torque(-CamNode.global_basis.z * (angular_damp * speed_scale + 1))
		going = true
		
	if going:
		lock_rotation = false
	else:
		lock_rotation = true


func _physics_process(_delta: float) -> void:
	respawn_safe_time = maxf(respawn_safe_time - _delta, 0.0)
	if global_position.y < -8.0 and not respawn_lock and respawn_safe_time <= 0.0:
		respawn_lock = true
		fell.emit()


func respawn_at(spawn_transform: Transform3D) -> void:
	var robot_root = get_parent()
	global_transform = spawn_transform
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	if robot_root != null:
		var body_rb = robot_root.get_node_or_null("body_rb") as RigidBody3D
		if body_rb != null:
			body_rb.global_transform = spawn_transform.translated_local(Vector3(0, 0.08, 0))
			body_rb.linear_velocity = Vector3.ZERO
			body_rb.angular_velocity = Vector3.ZERO
	respawn_safe_time = 1.0
	respawn_lock = false
