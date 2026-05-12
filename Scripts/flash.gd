extends Node3D

var timer : float = 0
var cooldown : float = 3

func _ready() -> void:
	$zone.monitoring = false

func _process(delta: float) -> void:
	timer -= delta
	timer = clampf(timer, 0, cooldown)
	if timer < cooldown - 0.1:
		visible = false
		$zone.monitoring = false
	if Input.is_action_just_pressed("Flash") and timer <= 0:
		visible = true
		$AudioStreamPlayer3D.play()
		$zone.monitoring = true
		timer = cooldown
	
func _on_area_3d_body_entered(body: Node3D) -> void:
	body.queue_free()
