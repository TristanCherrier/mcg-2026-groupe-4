extends Area3D

@export var speed := 13.0
@export var lifetime := 5.0
@export var damage := 15.0
@export var hit_message := "Impact détecté."

var direction := Vector3.FORWARD


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()


func launch(new_direction: Vector3) -> void:
	direction = new_direction.normalized()


func _on_body_entered(body: Node) -> void:
	if _node_or_parent_in_group(body, "car_player") or _node_or_parent_in_group(body, "ship_player"):
		GameState.damage_integrity(damage, hit_message)
		queue_free()


func _node_or_parent_in_group(node: Node, group_name: String) -> bool:
	var current: Node = node
	while current != null:
		if current.is_in_group(group_name):
			return true
		current = current.get_parent()
	return false
