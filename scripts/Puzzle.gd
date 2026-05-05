extends Area3D

@export var puzzle_id: int = 1

var player_inside := false
var solved := false
var dialog_open := false
var current_question: Dictionary = {}

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_inside = true
		if solved:
			_show_hud_msg("Enigme %d deja resolue !" % puzzle_id, 1.5)
		else:
			_show_hud_msg("Enigme %d : Appuie sur E" % puzzle_id, 3.0)

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_inside = false

func _unhandled_input(event: InputEvent) -> void:
	if solved or not player_inside or dialog_open:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E:
			get_viewport().set_input_as_handled()
			_open_dialog()

func _open_dialog() -> void:
	if dialog_open:
		return
	dialog_open = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	current_question = GameManager.get_next_question()

	var panel := PanelContainer.new()
	panel.name = "PuzzlePanel"
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(400, 220)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12)

	var title := Label.new()
	title.text = "=== Enigme %d ===" % puzzle_id
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)

	var question := Label.new()
	question.text = current_question["question"]
	question.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	question.add_theme_font_size_override("font_size", 18)
	question.autowrap_mode = TextServer.AUTOWRAP_WORD

	var line := LineEdit.new()
	line.name = "AnswerLine"
	line.placeholder_text = "Votre reponse..."
	line.max_length = 30
	line.custom_minimum_size = Vector2(320, 40)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 20)

	var btn_ok := Button.new()
	btn_ok.text = "Valider"
	btn_ok.custom_minimum_size = Vector2(110, 36)

	var btn_cancel := Button.new()
	btn_cancel.text = "Annuler"
	btn_cancel.custom_minimum_size = Vector2(110, 36)

	btn_row.add_child(btn_ok)
	btn_row.add_child(btn_cancel)

	vbox.add_child(title)
	vbox.add_child(question)
	vbox.add_child(line)
	vbox.add_child(btn_row)
	panel.add_child(vbox)

	var overlay := ColorRect.new()
	overlay.name = "Overlay"
	overlay.color = Color(0, 0, 0, 0.55)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var canvas := CanvasLayer.new()
	canvas.name = "PuzzleCanvas"
	canvas.layer = 10
	canvas.add_child(overlay)
	canvas.add_child(panel)
	get_tree().root.add_child(canvas)

	await get_tree().create_timer(0.05).timeout
	if is_instance_valid(line):
		line.grab_focus()

	btn_ok.pressed.connect(func(): _validate(line.text, canvas))
	btn_cancel.pressed.connect(func(): _close_dialog(canvas))
	line.text_submitted.connect(func(txt): _validate(txt, canvas))

func _validate(raw_text: String, canvas: Node) -> void:
	var rep := raw_text.strip_edges().to_lower()
	_close_dialog(canvas)

	if rep == current_question["answer"].to_lower():
		solved = true
		GameManager.mark_puzzle_solved(puzzle_id)
		GameManager.add_score(20)
		_show_hud_msg("Bonne reponse ! +20 points !", 2.0)
		var mesh := get_node_or_null("MeshInstance3D")
		if mesh:
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(0.2, 0.4, 1.0)
			mesh.set_surface_override_material(0, mat)
	else:
		GameManager.lose_score(5)
		_show_hud_msg("Mauvais ! -5 pts.  Indice : %s" % current_question["hint"], 3.0)

func _close_dialog(canvas: Node) -> void:
	dialog_open = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if is_instance_valid(canvas):
		canvas.queue_free()

func _show_hud_msg(msg: String, duration: float = 2.0) -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_message"):
		hud.show_message(msg, duration)
