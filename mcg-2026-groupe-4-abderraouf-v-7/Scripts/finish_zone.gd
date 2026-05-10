extends Area3D

signal finish_entered(body: Node)

@export var target_group := "foot_player"


func _on_body_entered(body: Node) -> void:
	if _node_or_parent_in_group(body, target_group):
		finish_entered.emit(body)


func _node_or_parent_in_group(node: Node, group_name: String) -> bool:
	var current: Node = node
	while current != null:
		if current.is_in_group(group_name):
			return true
		current = current.get_parent()
	return false
