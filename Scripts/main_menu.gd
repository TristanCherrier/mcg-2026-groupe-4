extends Control

@onready var start_button: Button = $CenterContainer/Panel/Margin/VBox/StartButton
@onready var controls_text: RichTextLabel = $CenterContainer/Panel/Margin/VBox/ControlsText


func _ready() -> void:
	start_button.grab_focus()
	controls_text.visible = false


func _on_start_button_pressed() -> void:
	GameState.reset_run()
	GameState.go_to_scene("res://Scenes/Levels/Classroom.tscn")


func _on_controls_button_pressed() -> void:
	controls_text.visible = not controls_text.visible


func _on_quit_button_pressed() -> void:
	get_tree().quit()
