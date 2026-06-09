extends CanvasLayer

func _ready():
	$TextureRect.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property($TextureRect, "modulate:a", 1.0, 1.5)
	tween.tween_interval(2.0)
	tween.tween_property($TextureRect, "modulate:a", 0.0, 1.0)
	tween.tween_callback(_go_to_menu)

func _go_to_menu():
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _input(event):
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
