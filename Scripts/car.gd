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
var maxSpeed : float = 10
var maxReverseSpeed : float = 20 #TODO
var acceleration : float = 2 #Barely matters. 
var deceleration : float = 2 #Same.
@export
var brakePower : float = 2 #Divides engineSpeed. Should be higher than 1.
@export
var eBrakeFriction : float = 0.3 #Front wheels friction for drifting.
var lerpFriction : float = 0
var grip : float = 1.0 #Used in sideways drag. Set to minGrip or maxGrip depending on E-Brake Input.
@export
var minGrip : float = 0.5
@export
var maxGrip : float = 10.0
var maxSteerAngle : float = deg_to_rad(60)
var wishSteerAngle : float;
var currentSteerAngle : float = 0.0
@export
var steerFactor : float = 8 #lower = more steer on e-brake
@export_range(0,0.1)
var adaptiveSteering : float #0 (full steering) to 0.1 (no steering).
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

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Chassis_Model = Chassis.get_child(0)
	wheels.append(WheelFrontRight)
	wheels.append(WheelFrontLeft)
	wheels.append(WheelBackRight)
	wheels.append(WheelBackLeft)
	
	for i in range(4):
		wheelRBs.append(wheels[i].get_child(0))
		wheelModels.append(wheelRBs[i].get_child(0).get_child(0))
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
	Chassis_Model.set_blend_shape_value(0, blend_chassis * 0.2)

	for i in range(4):
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
	
	if Input.is_action_pressed("Gas"):
		engineSpeed += acceleration
		going = true
	else:
		engineSpeed -= deceleration
		engineSpeed = max(engineSpeed, 0)
		going = false
	if Input.is_action_pressed("Brake"):
		# --- !!! IMPLEMENT REVERSE !!! ---
		engineSpeed /= brakePower
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
	
	var forwardForceLoss : float 
	forwardForceLoss = -global_basis.z.dot(-global_basis.z.rotated(Vector3.UP, currentSteerAngle))#0 is full loss, 1 is full preservation.
	
	if (backGrounded):
		#RWD
		apply_force(-global_basis.z * engineSpeed * (forwardForceLoss if frontGrounded else 1.0) * mass, backWheelsOffset + global_basis.y)
		DebugCube.global_position = global_position + backWheelsOffset
	if (frontGrounded):
		#Steering
		var steerVector : Vector3
		steerVector = -global_basis.z.rotated(global_basis.y, currentSteerAngle)
		apply_force(steerVector * -LocalVelocity.z * (1 - forwardForceLoss) * (maxGrip / steerFactor - grip / steerFactor + 1) * mass, frontWheelsOffset + global_basis.y)
		if frontGrounded or backGrounded:
			#Sideways Drag
			apply_central_force(global_basis.x * -LocalVelocity.x * grip * mass)
