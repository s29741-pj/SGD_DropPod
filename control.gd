extends Control

func _ready():
	$Button.pressed.connect(_back_pressed)

func _back_pressed():
	get_tree().change_scene_to_file(GameManager.paused_level)
	
func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_tree().change_scene_to_file("res://scenes/pause_menu.tscn")
