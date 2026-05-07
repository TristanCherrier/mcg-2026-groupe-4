extends Control


func _ready() -> void:
	$CenterContainer/Panel/VBoxContainer/ReasonLabel.text = GameState.defeat_reason
	$CenterContainer/Panel/VBoxContainer/RetryButton.grab_focus()


func _on_retry_button_pressed() -> void:
	GameState.set_integrity(100.0)
	GameState.set_energy(100.0)
	GameState.restart_level()


func _on_menu_button_pressed() -> void:
	GameState.open_menu()
