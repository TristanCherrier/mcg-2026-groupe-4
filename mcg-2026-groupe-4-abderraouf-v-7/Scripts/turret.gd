extends Node3D

@export var fire_interval := 2.0
@export var projectile_scene: PackedScene
@export var tracking_group := ""
@export var fire_direction := Vector3.FORWARD
@export var projectile_message := "Décharge latérale."
@export var active := true


func _ready() -> void:
	$Timer.wait_time = fire_interval
	if active:
		$Timer.start()


func _on_timer_timeout() -> void:
	if not active:
		return
	if projectile_scene == null:
		return
	var projectile := projectile_scene.instantiate()
	projectile.global_position = $SpawnPoint.global_position
	projectile.hit_message = projectile_message
	var direction := -global_basis.z
	if tracking_group != "":
		var target := get_tree().get_first_node_in_group(tracking_group) as Node3D
		if target != null:
			direction = ($SpawnPoint.global_position.direction_to(target.global_position))
	else:
		direction = (global_basis * fire_direction).normalized()
	projectile.launch(direction)
	get_tree().current_scene.add_child(projectile)


func set_active(value: bool) -> void:
	active = value
	if active:
		$Timer.start()
	else:
		$Timer.stop()
