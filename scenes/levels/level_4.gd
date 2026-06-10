extends Node2D
@onready var game_over_screen = $GameOverScreen
@onready var upgrade_screen = $UpgradeScreen

func _ready():
	GameManager.knife_only_mode = true
	GameManager.level_completed.connect(_on_level_completed)

func go_to_next_level(path):
	get_tree().paused = false
	GameManager.knife_only_mode = false
	get_tree().change_scene_to_file("res://scenes/end_screen.tscn")

func _on_level_completed():
	GameManager.knife_only_mode = false
	await get_tree().create_timer(1.5).timeout
	upgrade_screen.show_upgrades()
