extends Camera3D

@export var ship_rb: RigidBody3D
@export var target: Node3D
@export var follow_distance := 7.4
@export var follow_height := 5.0
@export var focus_height := 1.55
@export var lateral_bias := 0.7
@export var lead_amount := 0.2
@export var base_fov := 76.0
@export var max_fov_boost := 8.0


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	call_deferred("snap_to_target")


func _process(delta: float) -> void:
	var desired_focus := _compute_focus()
	var desired_position := _compute_position()
	var speed := ship_rb.linear_velocity.length()

	target.global_position = target.global_position.lerp(desired_focus, clampf(delta * 7.2, 0.0, 1.0))
	global_position = global_position.lerp(desired_position, clampf(delta * 5.8, 0.0, 1.0))
	fov = lerpf(fov, base_fov + minf(speed * 0.35, max_fov_boost), clampf(delta * 3.2, 0.0, 1.0))
	look_at(target.global_position, Vector3.UP)


func snap_to_target() -> void:
	var desired_focus := _compute_focus()
	var desired_position := _compute_position()
	var speed := ship_rb.linear_velocity.length()

	target.global_position = desired_focus
	global_position = desired_position
	fov = base_fov + minf(speed * 0.35, max_fov_boost)
	look_at(target.global_position, Vector3.UP)


func _compute_focus() -> Vector3:
	var velocity := ship_rb.linear_velocity
	var look_dir := -ship_rb.global_basis.z
	return ship_rb.global_position + Vector3.UP * focus_height + velocity * lead_amount + look_dir * 4.0 + ship_rb.global_basis.x * 0.35


func _compute_position() -> Vector3:
	var speed := ship_rb.linear_velocity.length()
	var look_dir := -ship_rb.global_basis.z
	return ship_rb.global_position - look_dir * (follow_distance + minf(speed * 0.035, 1.8)) + Vector3.UP * follow_height + ship_rb.global_basis.x * lateral_bias
