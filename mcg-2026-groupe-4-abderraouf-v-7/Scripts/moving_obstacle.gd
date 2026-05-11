extends StaticBody3D

@export var axis := Vector3(1, 0, 0)
@export var distance := 2.0
@export var speed := 1.2
@export var active := true

var start_position := Vector3.ZERO
var elapsed := 0.0


func _ready() -> void:
	start_position = global_position
	add_to_group("obstacle")


func _physics_process(delta: float) -> void:
	if not active:
		return
	elapsed += delta
	global_position = start_position + axis.normalized() * sin(elapsed * speed) * distance


func set_active(value: bool) -> void:
	active = value
