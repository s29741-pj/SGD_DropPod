extends Node2D

@onready var game_over_screen = $GameOverScreen
@onready var upgrade_screen = $UpgradeScreen
@onready var hud = $HUD
@onready var wave_label = $WaveLabel

var wave_configs = [
	{"enemy": "res://scenes/enemy.tscn", "count": 3},
	{"enemy": "res://scenes/enemy.tscn", "count": 5},
	{"enemy": "res://scenes/enemy_shooter.tscn", "count": 3},
	{"enemy": "res://scenes/heavy_enemy.tscn", "count": 2},
	{"enemy": "res://scenes/enemy.tscn", "count": 8}
]

var spawn_points = []

func _ready():
	GameManager.wave_completed.connect(_on_wave_completed)
	GameManager.level_completed.connect(_on_level_completed)
	spawn_points = $SpawnPoints.get_children()
	await get_tree().create_timer(2.0).timeout
	start_next_wave()

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
	await get_tree().create_timer(1.5).timeout
	upgrade_screen.show_upgrades()
