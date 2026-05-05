extends AnimatableBody3D

@export var amplitude: float = 3.0
@export var speed: float = 1.5

var origin: Vector3
var t: float = 0.0

func _ready() -> void:
	origin = position

func _physics_process(delta: float) -> void:
	t += delta * speed
	position = origin + Vector3(sin(t) * amplitude, 0.0, 0.0)
