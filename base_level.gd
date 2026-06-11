extends Node2D

@onready var game_over_screen = $GameOverScreen
@onready var upgrade_screen = $UpgradeScreen
@export var droppod_scene: PackedScene
@export var droppod_spawn: Vector2 = Vector2(100, 200)
@onready var pause_menu = $PauseMenu

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		pause_menu.toggle_pause()

func _ready():
	if GameManager.knife_only_mode:
		get_node("Player").current_weapon = get_node("Player").weapons.find("knife")	
	GameManager.level_completed.connect(_on_level_completed)
	GameManager.kill_all_to_complete = false
	if droppod_scene:
		var droppod = droppod_scene.instantiate()
		droppod.position = droppod_spawn
		add_child(droppod)
		droppod.landing_complete.connect(_on_landing_complete)
		get_node("Player").visible = false
		get_node("Player").set_physics_process(false)
		get_node("Player").set_process_input(false)
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

func _on_level_completed():
	await get_tree().create_timer(1.5).timeout
	upgrade_screen.show_upgrades()

func go_to_next_level(path):
	get_tree().paused = false
	GameManager.enemies_remaining = 0
	get_tree().change_scene_to_file(path)


func _on_landing_complete():
	get_node("Player").visible = true
	get_node("Player").set_physics_process(true)
	get_node("Player").set_process_input(true)
