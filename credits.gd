extends Control

func _ready():
	$CenterContainer/VBoxContainer/Button.pressed.connect(_on_back_pressed)
	$CenterContainer/VBoxContainer/RichTextLabel.meta_clicked.connect(_on_link_clicked)

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_link_clicked(meta):
	OS.shell_open(str(meta))
