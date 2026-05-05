extends Area3D

@export var next_level: int = 3
@export var score_reward: int = 50
# IDs des enigmes requises pour passer ce niveau (laisser vide = pas de condition)
@export var required_puzzles: Array = []

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return

	# Vérification : toutes les enigmes requises sont-elles résolues ?
	if required_puzzles.size() > 0 and not GameManager.are_puzzles_solved(required_puzzles):
		var hud := get_tree().get_first_node_in_group("hud")
		if hud:
			hud.show_message("Resous toutes les enigmes d'abord !", 2.5)
		return

	GameManager.add_score(score_reward)
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		if next_level > 3:
			hud.show_message("Bravo ! Jeu terminé ! Score : %d" % GameManager.score, 4.0)
		else:
			hud.show_message("+%d points ! Niveau suivant..." % score_reward, 2.0)
	await get_tree().create_timer(2.0).timeout
	if next_level > 3:
		get_tree().quit()
	else:
		GameManager.go_to_level(next_level)
