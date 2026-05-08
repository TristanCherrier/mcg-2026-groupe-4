extends Node3D

@export
var Mode_Nodes : Array[Node]
var mode : int = 0

@export
var robot : Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Mode_Switch"):
		mode = (mode + 1) % Mode_Nodes.size()
		for i in range(Mode_Nodes.size()):
			var node : Node = Mode_Nodes[i]
			node.process_mode = PROCESS_MODE_DISABLED
			var camera : Camera3D = node.find_child("*cam")
			camera.current = false
		var node : Node = Mode_Nodes[mode]
		node.process_mode = PROCESS_MODE_ALWAYS
		var camera : Camera3D = node.find_child("*cam")
		camera.current = true
