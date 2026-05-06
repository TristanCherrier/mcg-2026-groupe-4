extends RigidBody3D

@export var exhaust: Node3D
@export var ascend_speed := 8.8
@export var forward_speed := 6.4
@export var strafe_speed := 5.8
@export var descend_speed := 5.4
@export var boost_speed := 10.8
@export var max_total_speed := 12.4
@export var energy_cost_per_second := 8.0
@export var passive_recharge_per_second := 18.0
@export var input_response := 7.8
@export var idle_brake := 5.8
@export var hover_brake := 7.0
@export var angular_stabilizer := 10.2
@export var tilt_smoothness := 7.0

var empty_warning_cooldown := 0.0
var frame_visual: Node3D = null
var flame_visual: Node3D = null
var visual_yaw := 0.0
var visual_pitch := 0.0


func _ready() -> void:
	can_sleep = false
	gravity_scale = 0.0
	linear_damp = 1.35
	angular_damp = 8.0
	frame_visual = get_node_or_null("ship_frame")
	if exhaust != null:
		flame_visual = exhaust.get_node_or_null("thruster_flame")


func _physics_process(delta: float) -> void:
	empty_warning_cooldown = maxf(0.0, empty_warning_cooldown - delta)

	var thrust_input := (
		Input.get_action_strength("move_forward")
		+ Input.get_action_strength("move_back")
		+ Input.get_action_strength("move_left")
		+ Input.get_action_strength("move_right")
		+ Input.get_action_strength("jump")
	)
	var thrust_ratio := clampf(thrust_input / 2.2, 0.0, 1.0)

	if thrust_input <= 0.01:
		GameState.restore_energy(passive_recharge_per_second * delta)

	if flame_visual != null:
		var desired_scale := Vector3.ONE * lerpf(0.78, 1.42, thrust_ratio)
		flame_visual.scale = flame_visual.scale.lerp(desired_scale, clampf(delta * 10.0, 0.0, 1.0))


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	state.angular_velocity = state.angular_velocity.lerp(Vector3.ZERO, clampf(state.step * angular_stabilizer, 0.0, 1.0))

	var local_velocity := global_basis.inverse() * state.linear_velocity
	var left_input := Input.get_action_strength("move_left")
	var right_input := Input.get_action_strength("move_right")
	var forward_input := Input.get_action_strength("move_forward")
	var back_input := Input.get_action_strength("move_back")
	var jump_input := Input.get_action_strength("jump")

	var desired_local_velocity := Vector3.ZERO
	desired_local_velocity.x = (right_input - left_input) * strafe_force()
	desired_local_velocity.y = (forward_input * ascend_speed) - (back_input * descend_speed) + (jump_input * boost_speed)
	desired_local_velocity.z = (-forward_input * forward_speed) + (back_input * forward_speed * 0.45)

	var requested_intensity := clampf(
		forward_input
		+ (back_input * 0.7)
		+ (absf(right_input - left_input) * 0.7)
		+ (jump_input * 0.85),
		0.0,
		1.85
	)
	var thrusting := requested_intensity > 0.01
	var thrust_ratio := 1.0

	if thrusting:
		var requested_energy := energy_cost_per_second * requested_intensity * state.step
		if GameState.energy > 0.0:
			var consumed_energy := minf(GameState.energy, requested_energy)
			thrust_ratio = clampf(consumed_energy / maxf(requested_energy, 0.001), 0.0, 1.0)
			GameState.set_energy(GameState.energy - consumed_energy)
		elif empty_warning_cooldown <= 0.0:
			empty_warning_cooldown = 1.2
			GameState.push_message("Plus d'energie : relache un instant pour recharger.", 1.8)

	desired_local_velocity *= thrust_ratio

	var response_weight := clampf(state.step * input_response, 0.0, 1.0)
	local_velocity = local_velocity.lerp(desired_local_velocity, response_weight)

	if not thrusting:
		local_velocity.x = lerpf(local_velocity.x, 0.0, clampf(state.step * idle_brake, 0.0, 1.0))
		local_velocity.z = lerpf(local_velocity.z, 0.0, clampf(state.step * idle_brake, 0.0, 1.0))
		local_velocity.y = lerpf(local_velocity.y, 0.0, clampf(state.step * hover_brake, 0.0, 1.0))

	if local_velocity.length() > max_total_speed:
		local_velocity = local_velocity.normalized() * max_total_speed
	if local_velocity.length() < 0.03 and not thrusting:
		local_velocity = Vector3.ZERO

	state.linear_velocity = global_basis * local_velocity

	var target_yaw := (right_input - left_input) * 0.56
	var target_pitch := (-forward_input * 0.3) + (back_input * 0.18) - (jump_input * 0.12)
	var smooth_weight := clampf(state.step * tilt_smoothness, 0.0, 1.0)
	visual_yaw = lerpf(visual_yaw, target_yaw, smooth_weight)
	visual_pitch = lerpf(visual_pitch, target_pitch, smooth_weight)

	if exhaust != null:
		exhaust.basis = Basis.IDENTITY.rotated(Vector3.UP, visual_yaw).rotated(Vector3.RIGHT, visual_pitch)
	if frame_visual != null:
		frame_visual.basis = Basis.IDENTITY.rotated(Vector3.UP, visual_yaw * 0.55).rotated(Vector3.RIGHT, visual_pitch * 0.68)


func strafe_force() -> float:
	return strafe_speed
