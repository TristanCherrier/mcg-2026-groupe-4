extends CharacterBody3D

@export var speed: float = 1.2
@export var score_penalty: int = 50
@export var damage_cooldown: float = 1.5

var _player_ball: RigidBody3D = null
var _cooldown_timer: float = 0.0
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

# Rayon de contact adapté au nouveau gabarit (capsule 0.22 + bille 0.11 + marge)
const CONTACT_DISTANCE := 0.42

@onready var glow_light: OmniLight3D = $GlowLight


func _ready() -> void:
	add_to_group("monster")
	# Continuer à tourner même pendant la pause (quiz)
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().physics_frame
	_find_player()


func _find_player() -> void:
	for node in get_tree().get_nodes_in_group("foot_player"):
		if node is RigidBody3D:
			_player_ball = node as RigidBody3D
			return


func _physics_process(delta: float) -> void:
	_cooldown_timer = maxf(_cooldown_timer - delta, 0.0)

	if _player_ball == null or not is_instance_valid(_player_ball):
		_find_player()
		return

	# Gravité
	if not is_on_floor():
		velocity.y -= _gravity * delta

	# Vecteur vers le joueur (plan horizontal seulement)
	var diff: Vector3 = _player_ball.global_position - global_position
	diff.y = 0.0
	var dist: float = diff.length()

	if dist > 0.05:
		var dir: Vector3 = diff / dist
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
		look_at(Vector3(_player_ball.global_position.x, global_position.y, _player_ball.global_position.z), Vector3.UP)
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	move_and_slide()

	# Contact : dégâts + petite impulsion pour ne pas coller
	var real_dist: float = global_position.distance_to(_player_ball.global_position)
	if real_dist < CONTACT_DISTANCE:
		# Repousser légèrement la bille pour qu'elle puisse se dégager
		var push: Vector3 = (_player_ball.global_position - global_position).normalized()
		push.y = 0.15
		_player_ball.apply_central_impulse(push * 2.5)
		_try_damage()

	# Effet lumineux pulsant
	if glow_light != null:
		glow_light.light_energy = 1.8 + sin(Time.get_ticks_msec() * 0.005) * 0.5


func _try_damage() -> void:
	if _cooldown_timer > 0.0:
		return
	_cooldown_timer = damage_cooldown
	GameState.add_points(-score_penalty)
	GameState.push_message("Le monstre vous a touché !  -%d points" % score_penalty, 2.0)
	_flash_danger()


func _flash_danger() -> void:
	if glow_light == null:
		return
	glow_light.light_energy = 8.0
	await get_tree().create_timer(0.12).timeout
	if is_instance_valid(glow_light):
		glow_light.light_energy = 1.8
