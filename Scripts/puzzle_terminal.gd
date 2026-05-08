extends Area3D

signal solved_terminal(terminal: Area3D)

@export_multiline var question := ""
@export var answers: Array = ["", "", ""]
@export var correct_index := 0
@export var objective_hint := ""
@export var screen_mode := false
@export var auto_open_on_approach := false

var solved := false
var player_in_range: Node = null
var quiz_open := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_apply_layout_mode()
	_update_visual()


func get_interaction_text() -> String:
	if solved:
		if screen_mode:
			return "Ecran scientifique stabilise"
		return "Terminal stabilisé"
	if screen_mode:
		return "Analyse automatique de l'ecran"
	return "Appuyer sur E pour analyser le terminal"


func interact(_player: Node) -> void:
	if solved:
		GameState.push_message("Ce terminal a déjà été réactivé.")
		return
	if quiz_open:
		return
	if objective_hint != "":
		GameState.push_message(objective_hint, 3.0)
	quiz_open = true
	GameState.request_quiz(self)


func _process(_delta: float) -> void:
	if screen_mode:
		return
	if player_in_range != null and not solved and not quiz_open and Input.is_action_just_pressed("interact"):
		interact(player_in_range)


func _input(event: InputEvent) -> void:
	if screen_mode:
		return
	if player_in_range == null or solved or quiz_open:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E or event.physical_keycode == KEY_E:
			interact(player_in_range)


func get_question() -> String:
	return question


func get_answers() -> Array[String]:
	return answers


func submit_answer(index: int) -> bool:
	quiz_open = false
	if solved:
		return true
	if index == correct_index:
		solved = true
		_update_visual()
		GameState.award_puzzle()
		solved_terminal.emit(self)
		return true
	return false

func _on_body_entered(body: Node) -> void:
	if solved:
		return
	if _node_or_parent_in_group(body, "foot_player"):
		player_in_range = body
		if screen_mode:
			GameState.push_message("Poste scientifique detecte.", 1.2)
			if auto_open_on_approach and not quiz_open:
				call_deferred("_open_from_approach")
		else:
			GameState.push_message("Terminal détecté : appuyez sur E.", 1.6)


func _on_body_exited(body: Node) -> void:
	if player_in_range == body:
		player_in_range = null


func _node_or_parent_in_group(node: Node, group_name: String) -> bool:
	var current: Node = node
	while current != null:
		if current.is_in_group(group_name):
			return true
		current = current.get_parent()
	return false


func _update_visual() -> void:
	$OmniLight3D.light_color = Color(0.25, 1, 0.45) if solved else Color(0.25, 0.72, 1.0)


func _apply_layout_mode() -> void:
	if not screen_mode:
		return


func _open_from_approach() -> void:
	if player_in_range == null or solved or quiz_open:
		return
	interact(player_in_range)
