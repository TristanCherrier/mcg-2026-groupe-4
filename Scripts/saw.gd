extends RigidBody3D

func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 5

func _process(delta: float) -> void:
	$Mesh.rotate_x(-8 * delta)

func _on_body_entered(body: Node3D) -> void:
	
	if body is RigidBody3D:
		body.apply_central_impulse(-global_basis.z * 10 * body.mass)
