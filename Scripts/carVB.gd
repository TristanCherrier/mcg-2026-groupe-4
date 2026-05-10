extends VehicleBody3D

@export
var Wheel_FrontRight : VehicleWheel3D
@export
var Wheel_FrontLeft : VehicleWheel3D
@export
var Wheel_BackRight : VehicleWheel3D
@export
var Wheel_BackLeft : VehicleWheel3D

var max_steer_angle : float = deg_to_rad(25)
var wish_steer_angle : float = 0
var smooth_steer_angle : float = 0
var deceleration_force : float = 0
var brake_force : float = 0
var rearLightsMaterial : BaseMaterial3D
var LocalVelocity : Vector3 = Vector3.ZERO
func get_LocalVelocity(): return LocalVelocity

func _ready() -> void:
	rearLightsMaterial = $Car/Car.get_active_material(4)

func _physics_process(delta: float) -> void:
	LocalVelocity = linear_velocity.rotated(global_basis.x, -global_rotation.x).rotated(global_basis.y, -global_rotation.y).rotated(global_basis.z, -global_rotation.z)
	
	if Input.is_action_pressed("Gas"):
		deceleration_force = 0
		Wheel_BackRight.engine_force = 6000
		Wheel_BackLeft.engine_force = 6000
	else:
		deceleration_force = 2
		Wheel_BackRight.engine_force = 0
		Wheel_BackLeft.engine_force = 0
		
	if Input.is_action_pressed("E-Brake"):
		Wheel_BackRight.wheel_friction_slip = 1.2
		Wheel_BackLeft.wheel_friction_slip = 1.2
	else:
		if LocalVelocity.z > 0:
			Wheel_BackRight.wheel_friction_slip = 1.6
			Wheel_BackLeft.wheel_friction_slip = 1.6
		else:
			Wheel_BackRight.wheel_friction_slip = 1.4
			Wheel_BackLeft.wheel_friction_slip = 1.4
		
	if Input.is_action_pressed("Brake"):
		for node : SpotLight3D in $rearLights.get_children():
			node.light_energy = 1
		rearLightsMaterial.emission_energy_multiplier = 4
		if LocalVelocity.z < -0.15 or LocalVelocity.z > 0.1:
			Wheel_BackRight.engine_force = -6000
			Wheel_BackLeft.engine_force = -6000
			Wheel_BackRight.wheel_friction_slip = .9
			Wheel_BackLeft.wheel_friction_slip = .9
			Wheel_FrontRight.wheel_friction_slip = 1
			Wheel_FrontLeft.wheel_friction_slip = 1
		else:
			Wheel_BackRight.engine_force = -2000
			Wheel_BackLeft.engine_force = -2000
		brake_force = 30
	else:
		for node : SpotLight3D in $rearLights.get_children():
			node.light_energy = 0.5
		rearLightsMaterial.emission_energy_multiplier = 2
		brake_force = 0
		Wheel_FrontRight.wheel_friction_slip = 1.5
		Wheel_FrontLeft.wheel_friction_slip = 1.5
	brake = deceleration_force + brake_force
		
	wish_steer_angle = 0
	if Input.is_action_pressed("Steer_Left"):
		wish_steer_angle += max_steer_angle
	if Input.is_action_pressed("Steer_Right"):
		wish_steer_angle += -max_steer_angle
	smooth_steer_angle = lerpf(smooth_steer_angle, wish_steer_angle, 10 * delta)
	steering = smooth_steer_angle
