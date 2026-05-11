extends Control


func _ready() -> void:
	$CenterContainer/VBoxContainer/ContinueButton.grab_focus()


func _on_continue_button_pressed() -> void:
	GameState.go_to_scene("res://Scenes/UI/MainMenu.tscn")
