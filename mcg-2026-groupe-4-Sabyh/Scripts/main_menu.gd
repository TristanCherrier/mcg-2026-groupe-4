extends Control


func _ready() -> void:
	$CenterContainer/Panel/VBoxContainer/StartButton.grab_focus()


func _on_start_button_pressed() -> void:
	GameState.reset_run()
	GameState.go_to_scene("res://Scenes/Levels/Level1.tscn")


func _on_controls_button_pressed() -> void:
	$CenterContainer/Panel/VBoxContainer/ControlsText.visible = not $CenterContainer/Panel/VBoxContainer/ControlsText.visible


func _on_quit_button_pressed() -> void:
	get_tree().quit()
