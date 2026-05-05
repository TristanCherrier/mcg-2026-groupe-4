extends Node

var score: int = 100
var current_level: int = 1
var game_over: bool = false

# Pool partagé de questions – mélangé, sans répétition jusqu'à épuisement
var _question_pool: Array = []

# Suivi des enigmes resolues : { puzzle_id: true }
var puzzles_solved: Dictionary = {}

func mark_puzzle_solved(pid: int) -> void:
	puzzles_solved[pid] = true

func are_puzzles_solved(ids: Array) -> bool:
	for pid in ids:
		if not puzzles_solved.get(pid, false):
			return false
	return true

# Banque complète de questions faciles
const ALL_QUESTIONS: Array = [
	# Maths simples
	{"question": "Combien font 2 + 2 ?", "answer": "4", "hint": "4"},
	{"question": "Combien font 3 x 3 ?", "answer": "9", "hint": "9"},
	{"question": "Combien font 10 - 4 ?", "answer": "6", "hint": "6"},
	{"question": "Combien font 5 x 2 ?", "answer": "10", "hint": "10"},
	{"question": "Combien font 8 + 7 ?", "answer": "15", "hint": "15"},
	{"question": "Combien font 20 / 4 ?", "answer": "5", "hint": "5"},
	{"question": "Combien font 3 + 6 ?", "answer": "9", "hint": "9"},
	{"question": "Combien font 4 x 4 ?", "answer": "16", "hint": "16"},
	{"question": "Combien font 12 - 5 ?", "answer": "7", "hint": "7"},
	{"question": "Combien font 6 + 9 ?", "answer": "15", "hint": "15"},
	{"question": "Combien font 10 x 2 ?", "answer": "20", "hint": "20"},
	{"question": "Combien font 18 / 3 ?", "answer": "6", "hint": "6"},
	{"question": "Combien font 7 + 8 ?", "answer": "15", "hint": "15"},
	{"question": "Combien font 5 x 5 ?", "answer": "25", "hint": "25"},
	{"question": "Combien font 30 - 12 ?", "answer": "18", "hint": "18"},
	# Géographie facile
	{"question": "Capitale de la France ?", "answer": "paris", "hint": "Paris"},
	{"question": "Capitale de l'Espagne ?", "answer": "madrid", "hint": "Madrid"},
	{"question": "Capitale de l'Italie ?", "answer": "rome", "hint": "Rome"},
	{"question": "Capitale de l'Allemagne ?", "answer": "berlin", "hint": "Berlin"},
	{"question": "Capitale du Japon ?", "answer": "tokyo", "hint": "Tokyo"},
	{"question": "Sur quel continent se trouve la France ?", "answer": "europe", "hint": "Europe"},
	{"question": "Quel ocean borde la France a l'ouest ?", "answer": "atlantique", "hint": "Atlantique"},
	{"question": "Dans quel pays se trouve la Tour Eiffel ?", "answer": "france", "hint": "France"},
	{"question": "Dans quel pays se trouve Big Ben ?", "answer": "angleterre", "hint": "Angleterre"},
	{"question": "Dans quel pays se trouve la Statue de la Liberte ?", "answer": "etats-unis", "hint": "Etats-Unis"},
	# Sciences faciles
	{"question": "Planete la plus grande du systeme solaire ?", "answer": "jupiter", "hint": "Jupiter"},
	{"question": "Combien de planetes dans le systeme solaire ?", "answer": "8", "hint": "8"},
	{"question": "De quelle couleur est le ciel par beau temps ?", "answer": "bleu", "hint": "Bleu"},
	{"question": "De quelle couleur est une banane mure ?", "answer": "jaune", "hint": "Jaune"},
	{"question": "A quelle temperature l'eau bout-elle (en degres) ?", "answer": "100", "hint": "100"},
	{"question": "Combien de pattes a une araignee ?", "answer": "8", "hint": "8"},
	{"question": "Combien de pattes a un insecte ?", "answer": "6", "hint": "6"},
	{"question": "De quelle couleur est une tomate mure ?", "answer": "rouge", "hint": "Rouge"},
	{"question": "Quel animal fait miaou ?", "answer": "chat", "hint": "Chat"},
	{"question": "Quel animal fait ouaf ?", "answer": "chien", "hint": "Chien"},
	# Culture générale facile
	{"question": "Combien de couleurs dans un arc-en-ciel ?", "answer": "7", "hint": "7"},
	{"question": "Combien de jours dans une semaine ?", "answer": "7", "hint": "7"},
	{"question": "Combien de mois dans une annee ?", "answer": "12", "hint": "12"},
	{"question": "Combien de saisons dans une annee ?", "answer": "4", "hint": "4"},
	{"question": "Combien de cotes a un triangle ?", "answer": "3", "hint": "3"},
	{"question": "Combien de cotes a un carre ?", "answer": "4", "hint": "4"},
	{"question": "Combien de joueurs dans une equipe de football ?", "answer": "11", "hint": "11"},
	{"question": "Combien d'heures dans une journee ?", "answer": "24", "hint": "24"},
	{"question": "Suite : 2, 4, 6, 8, ? ?", "answer": "10", "hint": "10"},
	{"question": "Suite : 1, 2, 3, 4, ? ?", "answer": "5", "hint": "5"},
]

func _ready() -> void:
	score = 100
	game_over = false
	puzzles_solved = {}
	_refill_pool()

func _refill_pool() -> void:
	_question_pool = ALL_QUESTIONS.duplicate()
	_question_pool.shuffle()

func get_next_question() -> Dictionary:
	if _question_pool.is_empty():
		_refill_pool()
	return _question_pool.pop_back()

func add_score(points: int) -> void:
	score += points

func lose_score(points: int) -> void:
	if game_over:
		return
	score -= points
	if score <= 0:
		score = 0
		trigger_game_over()

func trigger_game_over() -> void:
	if game_over:
		return
	game_over = true
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_game_over"):
		hud.show_game_over()
	await get_tree().create_timer(3.0).timeout
	score = 100
	game_over = false
	puzzles_solved = {}
	current_level = 1
	_refill_pool()
	get_tree().change_scene_to_file("res://scenes/Level1.tscn")

func go_to_level(level: int) -> void:
	current_level = level
	puzzles_solved = {}
	match level:
		1: get_tree().change_scene_to_file("res://scenes/Level1.tscn")
		2: get_tree().change_scene_to_file("res://scenes/Level2.tscn")
		3: get_tree().change_scene_to_file("res://scenes/Level3.tscn")
