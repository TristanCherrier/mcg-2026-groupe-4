extends RigidBody3D

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

var engineRotation : float = 0
var maxSpeed : float = 1
var maxReverseSpeed : float = 0.5 #TODO
var acceleration : float = 0.01
var deceleration : float = 0.01
var brakePower : float = 0.95 #multiplies engineRotation. Should be lower than 1.
var ebraking : int = 0
var minBackFriction : float = 0.1 #back wheels friction for drifting.
var maxBackFriction : float = 0.3
var backFriction : float = 0.3
var grip : float = 5
var maxSteerAngle : float = deg_to_rad(45)
var wishSteerAngle : float;
var currentSteerAngle : float = 0.0
@export_range(0,1)
var adaptiveSteering : float #0 (full steering) to 1 (no steering).
var going = false
var frontGrounded = false
var backGrounded = false

@export
var backWheelsOffset = Vector3.ZERO;
@export
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
		engineRotation += acceleration
	elif !Input.is_action_pressed("Brake"):
		engineRotation -= deceleration
		engineRotation = max(engineRotation, 0)
	if Input.is_action_pressed("Brake"):
		# --- !!! IMPLEMENT REVERSE !!! ---
		engineRotation -= acceleration * 2
		engineRotation *= brakePower

	if Input.is_action_pressed("E-Brake"):
		ebraking = 0
		backFriction = minBackFriction
		engineRotation *= brakePower
		for i in range(2,4):
			wheelRBs[i].physics_material_override.friction = 1
	else:
		ebraking = 1
		for i in range(2,4):
			wheelRBs[i].physics_material_override.friction = 0.0
		
	#for i in range(2,4):
		#wheelRBs[i].physics_material_override.friction = backFriction
	
	wishSteerAngle = 0.0
	if Input.is_action_pressed("Steer_Right"):
		wishSteerAngle = -maxSteerAngle / max(1, (abs(LocalVelocity.z) * adaptiveSteering / 10) + 1)
	if Input.is_action_pressed("Steer_Left"):
		wishSteerAngle = maxSteerAngle / max(1, (abs(LocalVelocity.z) * adaptiveSteering / 10) + 1)
	
	currentSteerAngle = lerp(currentSteerAngle, wishSteerAngle, 0.1)
	
	wheelModels[0].rotate_y((wishSteerAngle - currentSteerAngle) * 0.1)
	wheelModels[1].rotate_y((wishSteerAngle - currentSteerAngle) * 0.1)
	for i in range(2):
		wheelModels[i].rotate_object_local(Vector3.RIGHT, LocalVelocity.z / 100)
	for i in range(2, 4):
		wheelModels[i].rotate_object_local(Vector3.RIGHT, (LocalVelocity.z / 100) * ebraking)
	
	engineRotation = max(min(engineRotation, maxSpeed), -maxReverseSpeed)
	
	var forwardForceLoss : float 
	forwardForceLoss = -global_basis.z.dot(-global_basis.z.rotated(Vector3.UP, currentSteerAngle))#0 is full loss, 1 is full preservation.
	
	if backGrounded:
		#RWD
		apply_force(-global_basis.z * engineRotation * 20 * (forwardForceLoss if frontGrounded else 1.0) * mass, backWheelsOffset)
		apply_force(global_basis.x * -LocalVelocity.x * grip * mass * 0.5, backWheelsOffset)
	if frontGrounded:
		#Steering
		var steerVector : Vector3
		steerVector = -global_basis.z.rotated(global_basis.y, currentSteerAngle)
		apply_force(steerVector * -LocalVelocity.z * (1 - forwardForceLoss) * mass * 2, frontWheelsOffset)
		apply_force(global_basis.x * -LocalVelocity.x * grip * mass * 0.5, frontWheelsOffset)
