extends Node2D

func _ready():
	GameManager.level_completed.connect(_on_level_completed)

func _on_level_completed():
	print("POZIOM UKONCZONY!")
	await get_tree().create_timer(2.0).timeout
	# Tu później załadujesz następny poziom
	get_tree().reload_current_scene()
