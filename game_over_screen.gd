extends CanvasLayer

@onready var message_label = $VBoxContainer/MessageLabel
@onready var score_label = $VBoxContainer/ScoreLabel

func _ready():
	hide()

func show_game_over():
	get_tree().paused = true
	message_label.text = "MISSION FAILED"
	score_label.text = "SCORE: " + str(GameManager.score)
	show()

func show_mission_complete():
	get_tree().paused = true
	message_label.text = "MISSION COMPLETE"
	score_label.text = "SCORE: " + str(GameManager.score)
	show()

func _on_button_pressed():
	get_tree().paused = false
	GameManager.delete_checkpoint()
	GameManager.reset()
	get_tree().reload_current_scene()
	
