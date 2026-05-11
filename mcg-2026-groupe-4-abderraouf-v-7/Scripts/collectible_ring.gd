extends Area3D

signal ring_collected(ring: Area3D)

var collected := false


func _process(delta: float) -> void:
	rotation.y += delta * 1.7


func _on_body_entered(body: Node) -> void:
	if collected:
		return
	if _node_or_parent_in_group(body, "ship_player"):
		collected = true
		GameState.award_ring()
		GameState.restore_energy(20.0)
		ring_collected.emit(self)
		queue_free()


func _node_or_parent_in_group(node: Node, group_name: String) -> bool:
	var current: Node = node
	while current != null:
		if current.is_in_group(group_name):
			return true
		current = current.get_parent()
	return false
