extends Node

signal level_completed
signal game_over

var enemies_remaining = 0

func register_enemy():
	enemies_remaining += 1

func enemy_died():
	enemies_remaining -= 1
	if enemies_remaining <= 0:
		level_completed.emit()
