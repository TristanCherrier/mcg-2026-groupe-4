extends Node3D

var playerTarget : Node3D
@export
var animation_player : AnimationPlayer
@export
var audio_player : AudioStreamPlayer3D

func _ready() -> void:
	var anima : Animation = animation_player.get_animation("ani_ptitmonstre_gnaw")
	anima.track_set_enabled(4, true)
	audio_player.pitch_scale = 0.95
	animation_player.speed_scale = 0.6
	animation_player.play("ani_ptitmonstre_gnaw")
	audio_player.bus = "Tunnel"

func play_sound():
	pass

func defeat():
	GameState.set_next_level(GameState.DEFEAT_SCENE)
	GameState.defeat_reason = "Mission échouée"
	GameState.complete_level()

func _on_area_3d_body_entered(_body: Node3D) -> void:
	call_deferred("defeat")
	
