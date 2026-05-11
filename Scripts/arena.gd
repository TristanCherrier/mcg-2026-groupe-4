extends Node3D

@onready var hud: CanvasLayer = $HUD

var charges : int = 0
const required_charges : int = 3

func _ready() -> void:
	GameState.enter_level("Niveau 2 - Arène", scene_file_path)
	GameState.set_next_level("res://Scenes/Levels/Tunnel.tscn")
	GameState.set_objective("Avtivez toutes les stations.")
	GameState.set_help("Z pour accélérer, S pour ralentir, Q/D pour tourner, ESPACE pour déraper.")
	GameState.set_integrity(100.0)
	hud.configure("Niveau 2 - Arène", true, false)
	

func _on_charge_station_fully_charged() -> void:
	charges += 1
	GameState.add_points(100)
	GameState.set_integrity(GameState.integrity + 40)
	if charges >= required_charges:
		GameState.complete_level()
	

func _on_monster_player_damaged() -> void:
	GameState.set_integrity(GameState.integrity - 20)
	GameState.add_points(-30)
	if GameState.integrity <= 0:
		GameState.set_next_level(GameState.DEFEAT_SCENE)
		GameState.defeat_reason = "Mission échouée"
		GameState.complete_level()
		
