extends Node

@export
var player : Node3D
var playerTarget : Node3D
var timer : float = 2
var SmallMonster = load("res://SmallMonster.tscn")
@export
var spawnPoints : Array[Node3D]

func _ready() -> void:
	playerTarget = player.get_child(1).get_child(1).get_child(1)
	

func _process(delta: float) -> void:
	timer -= delta
	if timer < 0:
		spawn_smallmonster()
		timer = 3 + randf_range(-1,1)
		
func spawn_smallmonster():
	var node : Node3D = SmallMonster.instantiate()
	node.playerTarget = playerTarget
	add_child(node)
	node.set_owner(self.get_parent())
	set_children_owner(node, self.get_parent())
	node.set_display_folded(true)
	node.global_position = spawnPoints[randi_range(0,spawnPoints.size()-1)].global_position

func set_children_owner(node : Node, new_owner : Node):
	for i in range(node.get_child_count()):
		var child = node.get_child(i)
		child.set_owner(new_owner)
		set_children_owner(child, new_owner)
