extends RigidBody3D

@export
var exhaust : Node3D
@export
var flame : Node3D
@export
var sub_flame : MeshInstance3D
@export
var sub_flame2 : MeshInstance3D
@export
var thruster_light : OmniLight3D
@export
var audio_player : AudioStreamPlayer3D
var flame_scale : float = 0
var smooth_flame_scale : float = 0

var rotY : float
var rotX : float
var smooth_rotY : float
var smooth_rotX : float
var thrust_force : float = 20
var mouse_motion : Vector2
var LocalVelocity : Vector3 = Vector3.ZERO
func get_LocalVelocity(): return LocalVelocity

func _ready() -> void:
	Utils.schedule(audio_player, "play", 0.01)
	
func _process(delta: float) -> void:
	LocalVelocity = linear_velocity * basis
	smooth_flame_scale = lerpf(smooth_flame_scale, flame_scale, 10 * delta)
	flame.scale = Vector3.ONE * smooth_flame_scale
	flame.scale.z = smooth_flame_scale - LocalVelocity.z / 10
	thruster_light.light_energy = smooth_flame_scale
	audio_player.volume_db = -80 + smooth_flame_scale * 60
	audio_player.pitch_scale = 0.8 + smooth_flame_scale * 0.5
	audio_player.pitch_scale = audio_player.pitch_scale * (-LocalVelocity.z * 0.05 + 1)
	var blend_val = cos(Time.get_ticks_msec() / 30.0) / 2 + 0.5
	var blend_val2 = sin(Time.get_ticks_msec() / 30.0) / 2 + 0.5
	sub_flame.set_blend_shape_value(0, blend_val)
	sub_flame2.set_blend_shape_value(0, blend_val2)

func _integrate_forces(_state : PhysicsDirectBodyState3D) -> void:
	exhaust.basis = Basis.IDENTITY
	rotY = mouse_motion.x / 300
	rotX = mouse_motion.y / 300
	mouse_motion = Vector2.ZERO
	rotY = clampf(rotY, -.2, .2)
	rotX = clampf(rotX, -.2, .2)
	smooth_rotY = lerpf(smooth_rotY, rotY, 0.2)
	smooth_rotX = lerpf(smooth_rotX, rotX, 0.2)
	exhaust.rotate_object_local(exhaust.basis.y, smooth_rotY)
	exhaust.rotate_object_local(exhaust.basis.x, smooth_rotX)
	rotY = 0
	rotX = 0
	
	if Input.is_action_pressed("Ship_Thrust"):
		flame_scale = 1
		apply_force(-exhaust.global_basis.z * thrust_force * mass * (linear_damp+1), exhaust.position)
	else:
		flame_scale = 0
		

func _input(event):
	if event is InputEventMouseMotion:
		mouse_motion += event.relative
