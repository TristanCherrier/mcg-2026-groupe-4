extends Node3D

@export var friendly := false
@export var patrol_axis := Vector3(1, 0, 0)
@export var patrol_distance := 0.0
@export var patrol_speed := 1.0

var start_position := Vector3.ZERO
var elapsed := 0.0


func _ready() -> void:
	start_position = global_position
	_apply_visual_theme()


func _process(delta: float) -> void:
	elapsed += delta
	position = start_position
	if patrol_distance > 0.0 and patrol_axis != Vector3.ZERO:
		position += patrol_axis.normalized() * sin(elapsed * patrol_speed) * patrol_distance
	rotation.y += delta * (0.35 if friendly else 0.65)
	position.y = start_position.y + sin(elapsed * 2.0) * 0.05


func _apply_visual_theme() -> void:
	var base_color := Color(0.28, 0.68, 0.72) if friendly else Color(0.44, 0.18, 0.16)
	var emission_color := Color(0.54, 1.0, 0.92) if friendly else Color(1.0, 0.38, 0.18)
	for mesh in find_children("*", "MeshInstance3D"):
		var material := StandardMaterial3D.new()
		material.albedo_color = base_color
		material.metallic = 0.22
		material.roughness = 0.38
		material.emission_enabled = true
		material.emission = emission_color
		mesh.material_override = material
	var glow_light := $GlowLight as OmniLight3D
	glow_light.light_color = emission_color
	glow_light.light_energy = 1.2 if friendly else 1.45
