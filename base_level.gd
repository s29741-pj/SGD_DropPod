extends Node2D

@onready var game_over_screen = $GameOverScreen
@onready var upgrade_screen = $UpgradeScreen
@export var droppod_scene: PackedScene
@export var droppod_spawn: Vector2 = Vector2(100, 200)


func _ready():
	GameManager.level_completed.connect(_on_level_completed)
	if droppod_scene:
		var droppod = droppod_scene.instantiate()
		droppod.position = droppod_spawn
		add_child(droppod)
		droppod.landing_complete.connect(_on_landing_complete)
		get_node("Player").visible = false
		get_node("Player").set_physics_process(false)
		get_node("Player").set_process_input(false)

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
