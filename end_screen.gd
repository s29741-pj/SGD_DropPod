extends Control

func _ready():
	$ScoreLabel.text = "WYNIK: " + str(GameManager.score)

func _input(event):
	if event is InputEventKey and event.pressed:
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	if event is InputEventMouseButton and event.pressed:
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
