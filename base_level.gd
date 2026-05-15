extends Node2D

@onready var game_over_screen = $GameOverScreen
@onready var upgrade_screen = $UpgradeScreen

func _ready():
	GameManager.level_completed.connect(_on_level_completed)

func _on_level_completed():
	await get_tree().create_timer(1.5).timeout
	upgrade_screen.show_upgrades()

func go_to_next_level(path):
	get_tree().paused = false
	GameManager.enemies_remaining = 0
	get_tree().change_scene_to_file(path)
