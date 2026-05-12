extends Node

signal score_changed(value: int)
signal objective_changed(text: String)
signal help_changed(text: String)
signal message_requested(text: String, duration: float)
signal quiz_requested(terminal: Node)
signal integrity_changed(value: float)
signal energy_changed(value: float)

const TITLE_SCENE = "res://Scenes/UI/TitleScreen.tscn"
const MENU_SCENE = "res://Scenes/UI/MainMenu.tscn"
const VICTORY_SCENE = "res://Scenes/UI/VictoryScreen.tscn"
const DEFEAT_SCENE = "res://Scenes/UI/DefeatScreen.tscn"

var score = 0
var objective = ""
var help_text = ""
var current_level_path = ""
var current_level_name = ""
var next_level_path = ""
var defeat_reason = ""
var integrity = 100.0
var energy = 100.0
var rings_collected = 0
var checkpoints_reached = 0
var puzzles_solved = 0
var bonus_found = 0
var _restarting = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input_map()


func _setup_input_map() -> void:
	_ensure_action("move_forward", ["W", "Z", "Up"])
	_ensure_action("move_back", ["S", "Down"])
	_ensure_action("move_left", ["A", "Q", "Left"])
	_ensure_action("move_right", ["D", "Right"])
	_ensure_action("jump", ["Space"])
	_ensure_action("interact", ["E"])
	_ensure_action("toggle_view", ["V"])
	_ensure_action("toggle_pause", ["Escape"])
	_ensure_action("Ship_Thrust", ["W", "Z", "Up"])
	_ensure_action("Gas", ["W", "Z", "Up"])
	_ensure_action("Brake", ["S", "Down"])
	_ensure_action("Steer_Left", ["A", "Q", "Left"])
	_ensure_action("Steer_Right", ["D", "Right"])
	_ensure_action("E-Brake", ["Space"])


func _ensure_action(action_name: String, key_names: Array[String]) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	if not InputMap.action_get_events(action_name).is_empty():
		return
	for key_name in key_names:
		var event = InputEventKey.new()
		event.keycode = OS.find_keycode_from_string(key_name)
		InputMap.action_add_event(action_name, event)


func reset_run() -> void:
	score = 0
	objective = ""
	help_text = ""
	current_level_path = ""
	current_level_name = ""
	next_level_path = ""
	defeat_reason = ""
	integrity = 100.0
	energy = 100.0
	rings_collected = 0
	checkpoints_reached = 0
	puzzles_solved = 0
	bonus_found = 0
	_emit_all()


func enter_level(level_name: String, scene_path: String) -> void:
	current_level_name = level_name
	current_level_path = scene_path


func set_next_level(scene_path: String) -> void:
	next_level_path = scene_path


func set_objective(text: String) -> void:
	objective = text
	objective_changed.emit(objective)


func set_help(text: String) -> void:
	help_text = text
	help_changed.emit(help_text)


func push_message(text: String, duration: float = 2.5) -> void:
	message_requested.emit(text, duration)


func request_quiz(terminal: Node) -> void:
	quiz_requested.emit(terminal)


func add_points(amount: int) -> void:
	if _restarting:
		return
	score += amount
	if score < -300:
		score = -300
	score_changed.emit(score)
	if score <= -300:
		_restarting = true
		push_message("Score critique ! Redemarrage du niveau...", 2.0)
		Utils.schedule(self, "restart_level", 2)


func award_puzzle() -> void:
	puzzles_solved += 1
	add_points(100)


func award_bonus() -> void:
	bonus_found += 1
	add_points(50)


func award_checkpoint() -> void:
	checkpoints_reached += 1
	award_bonus()


func award_ring() -> void:
	rings_collected += 1
	award_bonus()


func award_level_finish() -> void:
	add_points(200)


func apply_fall_penalty() -> void:
	add_points(-50)


func set_integrity(value: float) -> void:
	integrity = clampf(value, 0.0, 100.0)
	integrity_changed.emit(integrity)


func damage_integrity(amount: float, reason: String = "") -> void:
	set_integrity(integrity - amount)
	if reason != "":
		push_message(reason)
	if integrity <= 0.0:
		open_defeat("Intégrité critique : le robot n'a pas résisté à l'incident.")


func repair_integrity(amount: float) -> void:
	set_integrity(integrity + amount)


func set_energy(value: float) -> void:
	energy = clampf(value, 0.0, 100.0)
	energy_changed.emit(energy)


func consume_energy(amount: float) -> bool:
	if energy <= 0.0:
		return false
	set_energy(energy - amount)
	return energy > 0.0


func restore_energy(amount: float) -> void:
	set_energy(energy + amount)


func go_to_scene(scene_path: String) -> void:
	for node in get_tree().get_nodes_in_group("small_monsters"):
		node.queue_free()
	get_tree().paused = false
	get_tree().change_scene_to_file(scene_path)


func restart_level() -> void:
	if current_level_path != "":
		score = 0
		_restarting = false
		score_changed.emit(score)
		go_to_scene(current_level_path)


func complete_level() -> void:
	award_level_finish()
	if next_level_path != "":
		go_to_scene(next_level_path)
	else:
		open_victory()


func open_menu() -> void:
	go_to_scene(MENU_SCENE)


func open_title() -> void:
	go_to_scene(TITLE_SCENE)


func open_victory() -> void:
	go_to_scene(VICTORY_SCENE)


func open_defeat(reason: String) -> void:
	defeat_reason = reason
	go_to_scene(DEFEAT_SCENE)


func _emit_all() -> void:
	score_changed.emit(score)
	objective_changed.emit(objective)
	help_changed.emit(help_text)
	integrity_changed.emit(integrity)
	energy_changed.emit(energy)
