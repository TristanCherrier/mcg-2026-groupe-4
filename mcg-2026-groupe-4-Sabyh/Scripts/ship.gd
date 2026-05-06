extends RigidBody3D

@export
var exhaust : Node3D

var rotY : float
var rotX : float
var smooth_rotY : float
var smooth_rotX : float
var thrust_force : float = 20
var energy_cost_per_second : float = 18.0
var passive_recharge_per_second : float = 8.0
var mouse_motion : Vector2
var empty_warning_cooldown := 0.0


func _physics_process(delta: float) -> void:
	empty_warning_cooldown = maxf(0.0, empty_warning_cooldown - delta)
	if not Input.is_action_pressed("Ship_Thrust"):
		GameState.restore_energy(passive_recharge_per_second * delta)


func _integrate_forces(state : PhysicsDirectBodyState3D) -> void:
	exhaust.basis = Basis.IDENTITY
	rotY = mouse_motion.x /150
	rotX = mouse_motion.y /150
	mouse_motion = Vector2.ZERO
	rotY = clampf(rotY, -.1, .1)
	rotX = clampf(rotX, -.1, .1)
	smooth_rotY = lerpf(smooth_rotY, rotY, 0.1)
	smooth_rotX = lerpf(smooth_rotX, rotX, 0.1)
	exhaust.rotate_object_local(exhaust.basis.y, smooth_rotY)
	exhaust.rotate_object_local(exhaust.basis.x, smooth_rotX)
	rotY = 0
	rotX = 0
	
	if Input.is_action_pressed("Ship_Thrust"):
		var requested_energy := energy_cost_per_second * state.step
		if GameState.energy > 0.0:
			var consumed_energy := minf(GameState.energy, requested_energy)
			var thrust_ratio := clampf(consumed_energy / requested_energy, 0.0, 1.0)
			GameState.set_energy(GameState.energy - consumed_energy)
			apply_force(-exhaust.global_basis.z * thrust_force * thrust_ratio * mass * (linear_damp + 1), exhaust.position)
		elif empty_warning_cooldown <= 0.0:
			empty_warning_cooldown = 1.2
			GameState.push_message("Énergie insuffisante : relâchez un instant pour recharger le propulseur.", 2.0)
	
func _input(event):
	if event is InputEventMouseMotion:
		mouse_motion += event.relative
