extends Area2D

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.play_victory()
		await get_tree().create_timer(1.5).timeout
		GameManager.advance_level()
		GameManager.level_completed.emit()
