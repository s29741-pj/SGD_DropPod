extends Node

signal level_completed

var enemies_remaining = 0
var score = 0
var mission_start_time = 0.0

func _ready():
	mission_start_time = Time.get_ticks_msec()

func register_enemy():
	enemies_remaining += 1

func enemy_died():
	enemies_remaining -= 1
	score += 100
	if enemies_remaining <= 0:
		_calculate_time_bonus()
		level_completed.emit()

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
