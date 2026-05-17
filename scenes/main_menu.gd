extends Control

func _ready():
	$VBoxContainer/StartButton.pressed.connect(_on_start_pressed)
	$VBoxContainer/QuitButton.pressed.connect(_on_quit_pressed)
	$VBoxContainer/ContinueButton.visible = GameManager.has_checkpoint()
	$VBoxContainer/ContinueButton.pressed.connect(_on_continue_pressed)
	
	
func _on_start_pressed():
	GameManager.reset()
	get_tree().change_scene_to_file("res://scenes/levels/level1.tscn")

func _on_quit_pressed():
	get_tree().quit()

func _on_continue_pressed():
	var data = GameManager.checkpoint_data
	GameManager.load_checkpoint()
	get_tree().change_scene_to_file(data["level"])
	
