extends CanvasLayer

@onready var controls_panel = $ControlsPanel

func _ready():
	hide()
	$VBoxContainer/ResumeButton.pressed.connect(_on_resume_pressed)
	$VBoxContainer/ControlsButton.pressed.connect(_on_controls_pressed)
	$VBoxContainer/MenuButton.pressed.connect(_on_menu_pressed)

	
func toggle_pause():
	if visible:
		hide()
		get_tree().paused = false
	else:
		show()
		get_tree().paused = true

func _on_resume_pressed():
	toggle_pause()

func _on_controls_pressed():
	controls_panel.visible = true

func _on_menu_pressed():
	get_tree().paused = false
	GameManager.reset()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	
func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if controls_panel.visible:
			controls_panel.visible = false
		else:
			toggle_pause()
