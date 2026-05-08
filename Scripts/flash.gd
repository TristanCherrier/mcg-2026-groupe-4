extends Node3D

var timer = 0

func _ready() -> void:
	$zone.monitoring = false

func _process(delta: float) -> void:
	timer -= delta
	clampf(timer, 0, 3)
	if timer < 2.9:
		visible = false
		$zone.monitoring = false
	if Input.is_action_just_pressed("Flash") and timer <= 0:
		visible = true
		$zone.monitoring = true
		timer = 3
	
func _on_area_3d_body_entered(body: Node3D) -> void:
	body.queue_free()
