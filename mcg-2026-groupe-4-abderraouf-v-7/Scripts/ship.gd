extends RigidBody3D

@export var exhaust: Node3D
@export var forward_speed := 9.0
@export var turn_speed := 1.8          # vitesse de rotation Q/D
@export var pitch_speed := 1.4         # vitesse montée/descente souris
@export var boost_speed := 14.0
@export var max_total_speed := 18.0
@export var energy_cost_per_second := 5.0
@export var passive_recharge_per_second := 22.0
@export var mouse_sensitivity := 0.003

var empty_warning_cooldown := 0.0
var frame_visual: Node3D = null
var flame_visual: Node3D = null
var _pitch := 0.0   # angle de tangage actuel (haut/bas)
var _yaw := 0.0     # angle de rotation horizontal actuel
var _mouse_y := 0.0 # mouvement souris vertical accumulé


func _ready() -> void:
	can_sleep = false
	gravity_scale = 0.0
	linear_damp = 1.8
	angular_damp = 12.0
	frame_visual = get_node_or_null("ship_frame")
	if exhaust != null:
		flame_visual = exhaust.get_node_or_null("thruster_flame")


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		# Souris haut/bas → monter/descendre l'angle
		_mouse_y += (event as InputEventMouseMotion).relative.y * mouse_sensitivity


func _physics_process(delta: float) -> void:
	empty_warning_cooldown = maxf(0.0, empty_warning_cooldown - delta)

	var forward_input := Input.get_action_strength("Roll_Forward")
	var back_input    := Input.get_action_strength("Roll_Back")
	var left_input    := Input.get_action_strength("Roll_Left")
	var right_input   := Input.get_action_strength("Roll_Right")
	var boost_input   := Input.get_action_strength("Ship_Thrust")

	var thrusting := (forward_input + back_input + boost_input) > 0.01

	# Énergie
	if not thrusting:
		GameState.restore_energy(passive_recharge_per_second * delta)

	# Rotation Q/D → tourne le vaisseau sur l'axe Y (yaw)
	_yaw -= (right_input - left_input) * turn_speed * delta
	rotation.y = _yaw

	# Souris → tangage (pitch) avec clamp pour pas faire de looping
	_pitch = clampf(_pitch - _mouse_y, deg_to_rad(-70), deg_to_rad(70))
	_mouse_y = 0.0
	rotation.x = _pitch

	# Vitesse : avancer dans la direction regardée
	var move_dir := -global_basis.z   # direction avant du vaisseau
	var desired_velocity := Vector3.ZERO

	if forward_input > 0.01:
		desired_velocity = move_dir * forward_speed * forward_input
	elif back_input > 0.01:
		desired_velocity = move_dir * -forward_speed * 0.6 * back_input

	if boost_input > 0.01:
		desired_velocity = move_dir * boost_speed * boost_input

	# Consommation énergie
	var intensity := forward_input + back_input * 0.6 + boost_input
	if intensity > 0.01 and GameState.energy > 0.0:
		var cost := energy_cost_per_second * intensity * delta
		GameState.set_energy(GameState.energy - minf(GameState.energy, cost))
	elif intensity > 0.01 and empty_warning_cooldown <= 0.0:
		empty_warning_cooldown = 1.2
		GameState.push_message("Plus d'énergie : relâche un instant pour recharger.", 1.8)
		desired_velocity = Vector3.ZERO

	# Appliquer la vitesse
	var current := linear_velocity
	linear_velocity = current.lerp(desired_velocity, clampf(delta * 6.0, 0.0, 1.0))
	if linear_velocity.length() > max_total_speed:
		linear_velocity = linear_velocity.normalized() * max_total_speed

	# Visuel flamme
	if flame_visual != null:
		var s := lerpf(0.78, 1.42, clampf(intensity / 1.5, 0.0, 1.0))
		flame_visual.scale = flame_visual.scale.lerp(Vector3.ONE * s, clampf(delta * 10.0, 0.0, 1.0))

	# Visuel inclinaison chassis
	if frame_visual != null:
		frame_visual.rotation.z = lerpf(frame_visual.rotation.z, (left_input - right_input) * 0.3, clampf(delta * 6.0, 0.0, 1.0))
