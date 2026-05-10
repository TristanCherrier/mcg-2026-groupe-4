extends Area3D

signal checkpoint_reached(checkpoint: Area3D)

@export var target_group := "car_player"
var activated := false


func _on_body_entered(body: Node) -> void:
	if activated:
		return
	if _node_or_parent_in_group(body, target_group):
		activated = true
		GameState.award_checkpoint()
		_apply_theme(Color(0.2, 0.85, 0.35))
		checkpoint_reached.emit(self)


func _ready() -> void:
	_apply_theme(Color(0.95, 0.72, 0.18))


func reset() -> void:
	activated = false
	_apply_theme(Color(0.95, 0.72, 0.18))


func _apply_theme(color: Color) -> void:
	var beam_material := StandardMaterial3D.new()
	beam_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	beam_material.albedo_color = Color(color.r, color.g, color.b, 0.22)
	beam_material.emission_enabled = true
	beam_material.emission = color
	beam_material.roughness = 0.18
	$BeamMesh.material_override = beam_material

	var ring_material := StandardMaterial3D.new()
	ring_material.albedo_color = color
	ring_material.emission_enabled = true
	ring_material.emission = color
	ring_material.metallic = 0.22
	ring_material.roughness = 0.26
	$RingTop.material_override = ring_material
	$RingBottom.material_override = ring_material
	$BeaconLight.light_color = color


func _node_or_parent_in_group(node: Node, group_name: String) -> bool:
	var current: Node = node
	while current != null:
		if current.is_in_group(group_name):
			return true
		current = current.get_parent()
	return false
