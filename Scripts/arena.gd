extends Node3D

@onready var hud: CanvasLayer = $HUD

var charges : int = 0
const required_charges : int = 3

func _ready() -> void:
	GameState.enter_level("Niveau 2 - Arène", scene_file_path)
	GameState.set_next_level("res://Scenes/Levels/Level3.tscn")
	GameState.set_objective("Passez les 3 checkpoints puis atteignez l'arrivée.")
	GameState.set_help("Z pour accélérer, S pour ralentir, Q/D pour tourner, espace pour dérapage.")
	GameState.set_integrity(100.0)
	hud.configure("Niveau 2 - Arène", true, false)
	

func _process(delta: float) -> void:
	pass

func _on_charge_station_fully_charged() -> void:
	charges += 1
	if charges >= required_charges:
		GameState.complete_level()
