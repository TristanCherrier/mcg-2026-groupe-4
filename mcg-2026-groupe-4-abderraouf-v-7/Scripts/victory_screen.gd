extends Control


func _ready() -> void:
	$CenterContainer/Panel/VBoxContainer/ScoreLabel.text = "Score global : %d" % GameState.score
	$CenterContainer/Panel/VBoxContainer/MenuButton.grab_focus()


func _on_menu_button_pressed() -> void:
	GameState.open_menu()


func _on_restart_button_pressed() -> void:
	GameState.reset_run()
	GameState.go_to_scene("res://Scenes/Levels/Level1.tscn")


func _on_quit_button_pressed() -> void:
	get_tree().quit()
