extends CanvasLayer

var message_timer = 0.0
var quiz_terminal: Node = null
var show_integrity = false
var show_energy = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("hud")
	GameState.score_changed.connect(_on_score_changed)
	GameState.objective_changed.connect(_on_objective_changed)
	GameState.help_changed.connect(_on_help_changed)
	GameState.message_requested.connect(_on_message_requested)
	GameState.quiz_requested.connect(_on_quiz_requested)
	GameState.integrity_changed.connect(_on_integrity_changed)
	GameState.energy_changed.connect(_on_energy_changed)
	_on_score_changed(GameState.score)
	_on_objective_changed(GameState.objective)
	_on_help_changed(GameState.help_text)
	_on_integrity_changed(GameState.integrity)
	_on_energy_changed(GameState.energy)
	$PausePanel.visible = false
	$QuizPanel.visible = false
	$PromptPanel.visible = false
	$MessageLabel.visible = false


func configure(level_title: String, wants_integrity: bool, wants_energy: bool) -> void:
	$TopPanel/Margin/VBox/LevelLabel.text = level_title
	show_integrity = wants_integrity
	show_energy = wants_energy
	$TopPanel/Margin/VBox/IntegrityLabel.visible = show_integrity
	$TopPanel/Margin/VBox/EnergyLabel.visible = show_energy


func set_prompt(text: String) -> void:
	$PromptPanel.visible = text != ""
	$PromptPanel/PromptLabel.text = text


func _process(delta: float) -> void:
	if message_timer > 0.0:
		message_timer -= delta
		if message_timer <= 0.0:
			$MessageLabel.visible = false
	if Input.is_action_just_pressed("toggle_pause") and not $QuizPanel.visible:
		_toggle_pause()


func _toggle_pause() -> void:
	var new_state = not get_tree().paused
	get_tree().paused = new_state
	$PausePanel.visible = new_state
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if new_state else Input.MOUSE_MODE_CAPTURED
	if new_state:
		$PausePanel/Panel/VBoxContainer/ResumeButton.grab_focus()


func _on_score_changed(value: int) -> void:
	$TopPanel/Margin/VBox/ScoreLabel.text = "Score : %d" % value


func _on_objective_changed(text: String) -> void:
	$TopPanel/Margin/VBox/ObjectiveLabel.text = "Objectif : %s" % text


func _on_help_changed(text: String) -> void:
	$TopPanel/Margin/VBox/HelpLabel.text = "Aide : %s" % text


func _on_message_requested(text: String, duration: float) -> void:
	$MessageLabel.text = text
	$MessageLabel.visible = true
	message_timer = duration


func _on_integrity_changed(value: float) -> void:
	$TopPanel/Margin/VBox/IntegrityLabel.text = "Intégrité : %d%%" % roundi(value)


func _on_energy_changed(value: float) -> void:
	$TopPanel/Margin/VBox/EnergyLabel.text = "Énergie : %d%%" % roundi(value)


func _on_quiz_requested(terminal: Node) -> void:
	if not terminal.has_method("get_answers"):
		return
	quiz_terminal = terminal
	get_tree().paused = true
	$QuizPanel.visible = true
	$QuizPanel/Panel/VBoxContainer/QuestionLabel.text = terminal.get_question()
	var answers: Array = terminal.get_answers()
	$QuizPanel/Panel/VBoxContainer/AnswerA.text = answers[0]
	$QuizPanel/Panel/VBoxContainer/AnswerB.text = answers[1]
	$QuizPanel/Panel/VBoxContainer/AnswerC.text = answers[2]
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$QuizPanel/Panel/VBoxContainer/AnswerA.grab_focus()


func _submit_quiz_answer(index: int) -> void:
	if quiz_terminal == null:
		return
	var correct: bool = bool(quiz_terminal.submit_answer(index))
	$QuizPanel.visible = false
	get_tree().paused = false
	quiz_terminal = null
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if correct:
		_on_message_requested("Bonne réponse : terminal stabilisé.", 2.5)
	else:
		_on_message_requested("Réponse incorrecte. Analysez encore la salle.", 2.5)


func _on_answer_a_pressed() -> void:
	_submit_quiz_answer(0)


func _on_answer_b_pressed() -> void:
	_submit_quiz_answer(1)


func _on_answer_c_pressed() -> void:
	_submit_quiz_answer(2)


func _on_resume_button_pressed() -> void:
	_toggle_pause()


func _on_menu_button_pressed() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	GameState.open_menu()
