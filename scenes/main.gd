extends Node2D
@onready var game_over_screen = $GameOverScreen
func _ready():
	GameManager.level_completed.connect(_on_level_completed)
func _on_level_completed():
	print("POZIOM UKONCZONY!")
	await get_tree().create_timer(2.0).timeout
	game_over_screen.show_mission_complete()
	# Tu później załadujesz następny poziom
