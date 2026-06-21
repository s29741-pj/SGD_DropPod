extends Node2D

@export var healthpack_scene: PackedScene
@export var ammo_scene: PackedScene

@onready var game_over_screen = $GameOverScreen
@onready var upgrade_screen = $UpgradeScreen
@onready var hud = $HUD
@onready var wave_label = $WaveLabel
@onready var pause_menu = $PauseMenu

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		pause_menu.toggle_pause()

var wave_configs = [
	{"enemy": "res://scenes/enemy.tscn", "count": 3},
	{"enemy": "res://scenes/enemy_shooter.tscn", "count": 3},
	#{"enemy": "res://scenes/enemy.tscn", "count": 5},
	#{"enemy": "res://scenes/heavy_enemy.tscn", "count": 2},
	#{"enemy": "res://scenes/enemy.tscn", "count": 8}
]

var spawn_points = []

func _ready():
	GameManager.current_wave = 0
	GameManager.wave_completed.connect(_on_wave_completed)
	GameManager.level_completed.connect(_on_level_completed)
	GameManager.kill_all_to_complete = false
	spawn_points = $SpawnPoints.get_children()
	await get_tree().create_timer(2.0).timeout
	start_next_wave()
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
	GameManager.enemies_remaining = 0
	get_tree().change_scene_to_file(path)

func spawn_pickups():
	if healthpack_scene:
		for node in get_tree().get_nodes_in_group("healthpack_spawn"):
			var hp = healthpack_scene.instantiate()
			hp.position = node.position
			add_child(hp)
	if ammo_scene:
		for node in get_tree().get_nodes_in_group("ammo_spawn"):
			var ammo = ammo_scene.instantiate()
			ammo.position = node.position
			add_child(ammo)

func start_next_wave():
	var wave_index = GameManager.current_wave
	if wave_index >= wave_configs.size():
		GameManager.level_completed.emit()
		return
	GameManager.start_wave(wave_index + 1)
	wave_label.text = "FALA " + str(GameManager.current_wave) + "/" + str(GameManager.total_waves)
	var config = wave_configs[wave_index]
	var enemy_scene = load(config["enemy"])
	for i in config["count"]:
		await get_tree().create_timer(0.5).timeout
		var enemy = enemy_scene.instantiate()
		var spawn = spawn_points[i % spawn_points.size()]
		enemy.position = spawn.global_position
		add_child(enemy)

func _on_wave_completed():
	wave_label.text = "FALA ODPARTA!"
	await get_tree().create_timer(3.0).timeout
	start_next_wave()

func _on_level_completed():
	GameManager.advance_level()
	await get_tree().create_timer(1.5).timeout
	upgrade_screen.show_upgrades()
