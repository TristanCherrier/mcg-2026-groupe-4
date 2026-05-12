extends Node3D

var playerTarget : Node3D
@export
var animation_player : AnimationPlayer 

func _ready() -> void:
	$AudioStreamPlayer3D.play()
	animation_player.play("ani_ptitmonstre_gnaw", -1, 0.5)

func defeat():
	GameState.set_next_level(GameState.DEFEAT_SCENE)
	GameState.defeat_reason = "Mission échouée"
	GameState.complete_level()

func _on_area_3d_body_entered(_body: Node3D) -> void:
	call_deferred("defeat")
	
