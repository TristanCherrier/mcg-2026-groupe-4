extends CharacterBody3D

@export var detect_radius: float = 6.0
@export var patrol_range: float = 2.0
## Contrainte Z indépendante (si 0, utilise patrol_range pour Z aussi)
@export var patrol_range_z: float = 0.0
## Si true, le monstre peut se déplacer librement sans contrainte de zone
@export var free_roam: bool = false

var home_position: Vector3
var player: Node3D = null
var damage_timer: float = 0.0
var patrol_dir: float = 1.0
var patrol_timer: float = 0.0

const SPEED = 2.2
const DAMAGE_COOLDOWN = 1.5

func _ready() -> void:
	add_to_group("monster")
	home_position = global_position

func _physics_process(delta: float) -> void:
	damage_timer -= delta
	patrol_timer -= delta

	if player == null:
		player = get_tree().get_first_node_in_group("player")

	var dist := INF
	if player:
		dist = global_position.distance_to(player.global_position)

	var desired_velocity := Vector3.ZERO
	var range_z := patrol_range_z if patrol_range_z > 0.0 else patrol_range

	if player != null and dist <= detect_radius:
		var dir := (player.global_position - global_position)
		dir.y = 0.0
		desired_velocity = dir.normalized() * SPEED
	else:
		if patrol_timer <= 0.0:
			patrol_dir *= -1.0
			patrol_timer = patrol_range / SPEED
		desired_velocity = Vector3(patrol_dir * SPEED, 0.0, 0.0)

	if not free_roam:
		if abs(global_position.x - home_position.x) >= patrol_range and \
		   sign(desired_velocity.x) == sign(global_position.x - home_position.x):
			desired_velocity.x = 0.0

		if abs(global_position.z - home_position.z) >= range_z and \
		   sign(desired_velocity.z) == sign(global_position.z - home_position.z):
			desired_velocity.z = 0.0

	velocity.x = desired_velocity.x
	velocity.z = desired_velocity.z
	velocity.y = 0.0

	global_position.y = home_position.y
	move_and_slide()

	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		if col.get_collider() == player and damage_timer <= 0.0:
			damage_timer = DAMAGE_COOLDOWN
			GameManager.lose_score(10)
			var hud := get_tree().get_first_node_in_group("hud")
			if hud and hud.has_method("show_message"):
				hud.show_message("-10 points !", 1.0)
