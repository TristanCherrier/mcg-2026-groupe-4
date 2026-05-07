extends RigidBody3D

@export
var DebugCube : Node3D
@export
var Chassis : Node3D
var Chassis_Model : MeshInstance3D
@export
var WheelFrontRight : Node3D
var WheelFrontRight_Model : MeshInstance3D
@export
var WheelFrontLeft : Node3D
var WheelFrontLeft_Model : MeshInstance3D
@export
var WheelBackRight : Node3D
var WheelBackRight_Model : MeshInstance3D
@export
var WheelBackLeft : Node3D
var WheelBackLeft_Model : MeshInstance3D

var engineSpeed : float = 0
var maxSpeed : float = 5.4
var maxReverseSpeed : float = 3.4
var acceleration : float = 0.7
var deceleration : float = 0.9
@export
var brakePower : float = 3.0
@export
var eBrakeFriction : float = 0.35
var lerpFriction : float = 0
var grip : float = 1.0 #Used in sideways drag. Set to minGrip or maxGrip depending on E-Brake Input.
@export
var minGrip : float = 0.8
@export
var maxGrip : float = 10.0
var maxSteerAngle : float = deg_to_rad(48)
var wishSteerAngle : float;
var currentSteerAngle : float = 0.0
@export
var steerFactor : float = 9 #lower = more steer on e-brake
@export
var steeringAssistForce : float = 6.5
@export
var steeringAssistTorque : float = 38.0
@export
var steeringAssistMinSpeed : float = 0.25
@export_range(0,0.1)
var adaptiveSteering : float = 0.05 #0 (full steering) to 0.1 (no steering).
var going = false
var frontGrounded = false
var backGrounded = false
var blend_chassis : float = 0
var blend_wheels : float = 0
var cycle : float
const frequency : float = 50

var backWheelsOffset = Vector3.ZERO;
var frontWheelsOffset = Vector3.ZERO;

var wheels : Array[Node3D]
var wheelRBs : Array[RigidBody3D]
var wheelModels : Array[MeshInstance3D]
var springs : Array[Joint3D]
var rays : Array[RayCast3D]
var wheel_mount_local_positions : Array[Vector3]
var wheel_mount_local_bases : Array[Basis]
var drive_enabled := true

const WHEEL_REST_OFFSET := -0.1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	can_sleep = false
	linear_damp = maxf(linear_damp, 0.55)
	angular_damp = maxf(angular_damp, 2.1)
	Chassis_Model = _find_first_mesh(Chassis)
	wheels.append(WheelFrontRight)
	wheels.append(WheelFrontLeft)
	wheels.append(WheelBackRight)
	wheels.append(WheelBackLeft)
	
	for i in range(4):
		wheel_mount_local_positions.append(wheels[i].position)
		wheel_mount_local_bases.append(wheels[i].basis)
		wheelRBs.append(wheels[i].get_child(0))
		wheelModels.append(_find_first_mesh(wheelRBs[i]))
		springs.append(wheels[i].get_child(1))
		springs[i].node_a = self.get_path()
		rays.append(wheelRBs[i].get_child(1))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	cycle += delta
	cycle = fmod(cycle, TAU)
	if(going):
		blend_wheels = lerp(blend_wheels, cos(cycle * frequency) / 2 + 0.5, 0.2)
		blend_chassis = lerp(blend_chassis, sin(cycle * frequency / 1.7) / 2 + 0.5, 0.2)
	else:
		blend_wheels = lerp(blend_wheels, 0.0, 0.1)
		blend_chassis = lerp(blend_chassis, 0.0, 0.1)
	if _has_blend_shapes(Chassis_Model):
		Chassis_Model.set_blend_shape_value(0, blend_chassis * 0.2)

	for i in range(4):
		if _has_blend_shapes(wheelModels[i]):
			wheelModels[i].set_blend_shape_value(0, blend_wheels)

func _physics_process(_delta: float) -> void:
	backWheelsOffset = (wheelRBs[2].global_position + wheelRBs[3].global_position) / 2 - global_position
	frontWheelsOffset = (wheelRBs[0].global_position + wheelRBs[1].global_position) / 2 - global_position
	
	frontGrounded = false
	for i in range(2): #Front wheels only for Steering.
		if (rays[i].is_colliding()):
			frontGrounded = true
	
	backGrounded = false
	for i in range(2,4): #Back wheels only for RWD.
		if (rays[i].is_colliding()):
			backGrounded = true
	
	
func _integrate_forces(_state : PhysicsDirectBodyState3D) -> void:
	var LocalVelocity : Vector3
	LocalVelocity = linear_velocity.rotated(global_basis.x, -global_rotation.x).rotated(global_basis.y, -global_rotation.y).rotated(global_basis.z, -global_rotation.z)

	if not drive_enabled:
		engineSpeed = 0.0
		going = false
		currentSteerAngle = lerp(currentSteerAngle, 0.0, 0.15)
		wheelModels[0].rotation = Vector3(0, currentSteerAngle, 0)
		wheelModels[1].rotation = Vector3(0, currentSteerAngle, 0)
		linear_velocity *= 0.92
		angular_velocity *= 0.85
		return
	
	if Input.is_action_pressed("Gas"):
		if engineSpeed < 0.0:
			engineSpeed = move_toward(engineSpeed, 0.0, acceleration * 1.35)
		else:
			engineSpeed += acceleration
	elif Input.is_action_pressed("Brake"):
		if LocalVelocity.z < -0.4 or engineSpeed > 0.15:
			engineSpeed = move_toward(engineSpeed, 0.0, brakePower * 0.42)
		else:
			engineSpeed -= acceleration * 0.78
	else:
		engineSpeed = move_toward(engineSpeed, 0.0, deceleration)

	going = absf(engineSpeed) > 0.08
	if Input.is_action_pressed("E-Brake"):
		grip = lerp(grip, minGrip, 0.3)
		lerpFriction = lerp(lerpFriction, eBrakeFriction, 0.03)
	else:
		grip = lerp(grip, maxGrip, 0.02)
		lerpFriction = lerp(lerpFriction, 0.0, 0.1)
		
	for i in range(4):
		wheelRBs[i].physics_material_override.friction = lerpFriction
	
	wishSteerAngle = 0.0
	if Input.is_action_pressed("Steer_Right"):
		wishSteerAngle = -maxSteerAngle / max(1, (abs(LocalVelocity.z) * adaptiveSteering) + 1)
	if Input.is_action_pressed("Steer_Left"):
		wishSteerAngle = maxSteerAngle / max(1, (abs(LocalVelocity.z) * adaptiveSteering) + 1)
	
	currentSteerAngle = lerp(currentSteerAngle, wishSteerAngle, 0.1)
	wheelModels[0].rotation = Vector3(0, currentSteerAngle, 0)
	wheelModels[1].rotation = Vector3(0, currentSteerAngle, 0)
	
	engineSpeed = max(min(engineSpeed, maxSpeed), -maxReverseSpeed)
	var tractionGrounded := frontGrounded or backGrounded
	var forwardVector := -global_basis.z
	
	var forwardForceLoss : float 
	forwardForceLoss = clampf(forwardVector.dot(forwardVector.rotated(global_basis.y, currentSteerAngle)), 0.0, 1.0)#0 is full loss, 1 is full preservation.
	
	if (backGrounded):
		#RWD
		apply_force(forwardVector * engineSpeed * (forwardForceLoss if frontGrounded else 1.0) * mass, backWheelsOffset + global_basis.y)
		DebugCube.global_position = global_position + backWheelsOffset
	if tractionGrounded:
		# Steering still uses the original front-axle push, but we keep it active
		# as long as the car has traction so the chassis really changes direction.
		var steerVector : Vector3
		steerVector = forwardVector.rotated(global_basis.y, currentSteerAngle)
		var steeringForceGain : float = abs(LocalVelocity.z) * (1 - forwardForceLoss) * (maxGrip / steerFactor - grip / steerFactor + 1)
		apply_force(steerVector * steeringForceGain * mass, frontWheelsOffset + global_basis.y)
		if abs(LocalVelocity.z) > steeringAssistMinSpeed and abs(currentSteerAngle) > 0.01:
			apply_force(global_basis.x * currentSteerAngle * abs(LocalVelocity.z) * steeringAssistForce * mass, frontWheelsOffset + global_basis.y)
			apply_torque(global_basis.y * currentSteerAngle * abs(LocalVelocity.z) * steeringAssistTorque * mass)
		if tractionGrounded:
			#Sideways Drag
			apply_central_force(global_basis.x * -LocalVelocity.x * grip * mass)


func reset_vehicle(world_transform: Transform3D) -> void:
	var stable_basis := world_transform.basis.orthonormalized()
	global_transform = Transform3D(stable_basis, world_transform.origin)
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	sleeping = false
	engineSpeed = 0.0
	wishSteerAngle = 0.0
	currentSteerAngle = 0.0
	going = false

	for i in range(wheels.size()):
		wheels[i].global_basis = stable_basis * wheel_mount_local_bases[i]
		wheels[i].global_position = world_transform.origin + stable_basis * wheel_mount_local_positions[i]
		wheelRBs[i].global_basis = stable_basis
		wheelRBs[i].global_position = wheels[i].global_position + stable_basis.y * WHEEL_REST_OFFSET
		wheelRBs[i].linear_velocity = Vector3.ZERO
		wheelRBs[i].angular_velocity = Vector3.ZERO
		wheelRBs[i].sleeping = false


func set_drive_enabled(value: bool) -> void:
	drive_enabled = value
	if not drive_enabled:
		engineSpeed = 0.0
		going = false


func _find_first_mesh(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node as MeshInstance3D

	for child in node.get_children():
		var mesh := _find_first_mesh(child)
		if mesh != null:
			return mesh

	return null


func _has_blend_shapes(mesh: MeshInstance3D) -> bool:
	return mesh != null and mesh.mesh != null and mesh.mesh.get_blend_shape_count() > 0
