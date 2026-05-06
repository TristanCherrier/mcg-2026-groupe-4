extends Area3D

signal solved_terminal(terminal: Area3D)

@export_multiline var question := ""
@export var answers: Array = ["", "", ""]
@export var correct_index := 0
@export var objective_hint := ""

var solved := false
var player_in_range: Node = null
var quiz_open := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_update_visual()


func get_interaction_text() -> String:
	if solved:
		return "Terminal stabilisé"
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
	if player_in_range != null and not solved and not quiz_open and Input.is_action_just_pressed("interact"):
		interact(player_in_range)


func _input(event: InputEvent) -> void:
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
	var body_material := StandardMaterial3D.new()
	body_material.albedo_color = Color(0.22, 0.76, 0.46, 1) if solved else Color(0.23, 0.27, 0.34, 1)
	body_material.metallic = 0.18
	body_material.roughness = 0.3
	body_material.emission_enabled = true
	body_material.emission = Color(0.16, 0.95, 0.44, 1) if solved else Color(0.22, 0.68, 1.0, 1)
	$MeshInstance3D.material_override = body_material

	var screen_material := StandardMaterial3D.new()
	screen_material.albedo_color = Color(0.76, 0.92, 1.0, 1) if solved else Color(0.18, 0.24, 0.34, 1)
	screen_material.emission_enabled = true
	screen_material.emission = Color(0.42, 1.0, 0.7, 1) if solved else Color(0.2, 0.55, 1.0, 1)
	$ScreenMesh.material_override = screen_material

	var accent_material := StandardMaterial3D.new()
	accent_material.albedo_color = Color(1.0, 0.83, 0.28) if solved else Color(0.98, 0.52, 0.24)
	accent_material.emission_enabled = true
	accent_material.emission = accent_material.albedo_color
	$AccentMesh.material_override = accent_material

	$OmniLight3D.light_color = Color(0.25, 1, 0.45) if solved else Color(0.25, 0.65, 1.0)
