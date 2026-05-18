extends Node3D

@onready var hud: CanvasLayer = $HUD

@export
var player_body : Node3D
@export
var FollowNode : PathFollow3D
@export
var audio_players : Array[AudioStreamPlayer3D]
var wish_speed : float = 90
var speed : float = 90
var max_speed : float = 90
var acceleration : float = 10
var chase : bool = false

func _ready() -> void:
	GameState.enter_level("Niveau 3 - Poursuite", scene_file_path)
	GameState.set_next_level("")
	GameState.set_objective("Echappez vous!")
	GameState.set_help("Z pour avancer, Souris pour s'orienter.")
	hud.configure("Niveau 3 - Poursuite", false, false)
	audio_players[0].play()
	FollowNode.visible = false
	FollowNode.progress = 0

func _process(delta: float) -> void:
	if chase: 
		var distance_to_player : float = FollowNode.global_position.distance_squared_to(player_body.global_position)
		wish_speed += acceleration * delta
		wish_speed = clampf(wish_speed, 0, max_speed)
		speed = wish_speed * clampf(remap(distance_to_player, 30, 180, 0.5, 1), 0.5, 1)
		FollowNode.progress += delta * speed

func _on_grate_zone_area_entered(_area: Area3D) -> void:
	audio_players[1].play()

func _on_start_zone_body_entered(_body: Node3D) -> void:
	FollowNode.visible = true
	FollowNode.process_mode = Node.PROCESS_MODE_INHERIT
	chase = true

func _on_finish_body_entered(_body: Node3D) -> void:
	GameState.call_deferred("complete_level")
