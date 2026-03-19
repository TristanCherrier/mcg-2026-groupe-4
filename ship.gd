extends RigidBody3D

@export
var exhaust : Node3D

var rotY : float
var rotX : float
var smooth_rotY : float
var smooth_rotX : float
var thrust_force : float = 20
var mouse_motion : Vector2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("Ship ready")
	
func _integrate_forces(state : PhysicsDirectBodyState3D) -> void:
	exhaust.basis = Basis.IDENTITY
	rotY = mouse_motion.x /50
	rotX = mouse_motion.y /50
	mouse_motion = Vector2.ZERO
	rotY = clampf(rotY, -.5, .5)
	rotX = clampf(rotX, -.5, .5)
	smooth_rotY = lerpf(smooth_rotY, rotY, 0.1)
	smooth_rotX = lerpf(smooth_rotX, rotX, 0.1)
	exhaust.rotate_object_local(exhaust.basis.y, smooth_rotY)
	exhaust.rotate_object_local(exhaust.basis.x, smooth_rotX)
	rotY = 0
	rotX = 0
	
	if Input.is_action_pressed("Ship_Thrust"):
		apply_force(-exhaust.global_basis.z * thrust_force * mass * (linear_damp+1), exhaust.position)
	
func _input(event):
	if event is InputEventMouseMotion:
		mouse_motion += event.relative
