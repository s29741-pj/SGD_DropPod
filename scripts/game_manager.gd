extends Node

signal level_completed

var enemies_remaining = 0
var score = 0
var mission_start_time = 0.0

var upgrades = {
	"bolter_damage": 0,
	"bolter_fire_rate": 0,
	"gatling_fire_rate": 0,
	"gatling_heat": 0,
	"max_hp": 0,
	"max_ammo": 0
}

var next_level = "res://scenes/levels/level2.tscn"
var current_level = 1

var current_wave = 0
var total_waves = 5
var wave_in_progress = false
var knife_only_mode = false

signal wave_started(wave_number)
signal wave_completed
signal all_waves_completed

var checkpoint_data = {}


func save_checkpoint(player_pos: Vector2, level_path: String):
	checkpoint_data = {
		"player_x": player_pos.x,
		"player_y": player_pos.y,
		"level": level_path,
		"hp": checkpoint_data.get("hp", 5),
		"ammo_bolter": checkpoint_data.get("ammo_bolter", 30),
		"ammo_gatling": checkpoint_data.get("ammo_gatling", 100),
		"score": score,
		"upgrades": upgrades.duplicate()
	}
	_write_save()

func _write_save():
	var file = FileAccess.open("user://save.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(checkpoint_data))
	file.close()

func load_checkpoint():
	if not FileAccess.file_exists("user://save.json"):
		return false
	var file = FileAccess.open("user://save.json", FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	if data == null:
		return false
	checkpoint_data = data
	score = data["score"]
	upgrades = data["upgrades"]
	return true

func has_checkpoint():
	return FileAccess.file_exists("user://save.json")

func delete_checkpoint():
	if FileAccess.file_exists("user://save.json"):
		DirAccess.remove_absolute("user://save.json")

func advance_level():
	current_level += 1
	match current_level:
		2:
			next_level = "res://scenes/levels/level2.tscn"
		3:
			next_level = "res://scenes/levels/level3.tscn"
		4:
			next_level = "res://scenes/levels/level4.tscn"

const UPGRADE_COST = 200

func _ready():
	mission_start_time = Time.get_ticks_msec()

func register_enemy():
	enemies_remaining += 1

func enemy_died():
	enemies_remaining -= 1
	score += 100
	if enemies_remaining <= 0:
		if wave_in_progress:
			wave_in_progress = false
			wave_completed.emit()
		else:
			_calculate_time_bonus()
			level_completed.emit()

func start_wave(wave_number):
	current_wave = wave_number
	wave_in_progress = true
	enemies_remaining = 0
	wave_started.emit(wave_number)

func _calculate_time_bonus():
	var elapsed = (Time.get_ticks_msec() - mission_start_time) / 1000.0
	if elapsed < 30.0:
		score += 500
		print("CZAS BONUS: +500")
	elif elapsed < 60.0:
		score += 250
		print("CZAS BONUS: +250")
	elif elapsed < 120.0:
		score += 100
		print("CZAS BONUS: +100")

func reset():
	enemies_remaining = 0
	score = 0
	mission_start_time = Time.get_ticks_msec()
