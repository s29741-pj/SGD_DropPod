extends Node2D
@onready var game_over_screen = $GameOverScreen
@onready var upgrade_screen = $UpgradeScreen

func _ready():
	GameManager.knife_only_mode = true
	GameManager.level_completed.connect(_on_level_completed)
	# Automatyczny checkpoint na starcie poziomu
	await get_tree().process_frame
	var player = get_node("Player")
	GameManager.save_checkpoint(
		player.global_position,
		get_tree().current_scene.scene_file_path
	)
	GameManager.checkpoint_data["hp"] = player.hp
	GameManager.checkpoint_data["ammo_bolter"] = player.ammo["bolter"]
	GameManager.checkpoint_data["ammo_gatling"] = player.ammo.get("gatling", 0)
	GameManager.checkpoint_data["has_gatling"] = player.has_gatling
	GameManager._write_save()

func go_to_next_level(path):
	get_tree().paused = false
	GameManager.knife_only_mode = false
	get_tree().change_scene_to_file("res://scenes/end_screen.tscn")

func _on_level_completed():
	GameManager.knife_only_mode = false
	await get_tree().create_timer(1.5).timeout
	upgrade_screen.show_upgrades()
