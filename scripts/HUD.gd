extends CanvasLayer

@onready var score_label: Label = $VBox/ScoreLabel
@onready var level_label: Label = $VBox/LevelLabel
@onready var message_label: Label = $MessageLabel

var _msg_tween: Tween = null

func _ready() -> void:
	add_to_group("hud")
	message_label.visible = false
	message_label.modulate = Color(1, 1, 1, 1)

func _process(_delta: float) -> void:
	score_label.text = "Points : %d" % GameManager.score
	level_label.text = "Niveau : %d" % GameManager.current_level
	# Couleur du score selon la valeur
	if GameManager.score >= 70:
		score_label.modulate = Color(0.4, 1.0, 0.4, 1)
	elif GameManager.score >= 40:
		score_label.modulate = Color(1.0, 0.85, 0.2, 1)
	else:
		score_label.modulate = Color(1.0, 0.3, 0.3, 1)

func show_message(text: String, duration: float = 2.0) -> void:
	if _msg_tween:
		_msg_tween.kill()
	message_label.text = text
	message_label.modulate = Color(1, 1, 1, 1)
	message_label.visible = true
	_msg_tween = create_tween()
	_msg_tween.tween_interval(duration - 0.4)
	_msg_tween.tween_property(message_label, "modulate", Color(1, 1, 1, 0), 0.4)
	_msg_tween.tween_callback(func(): message_label.visible = false)

func show_game_over() -> void:
	message_label.text = "GAME OVER ! Retour au debut..."
	message_label.modulate = Color(1, 0.2, 0.2, 1)
	message_label.visible = true
