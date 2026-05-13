extends Node2D

@export var enemy_scene: PackedScene
@export var spawn_count: int = 3
@export var spawn_delay: float = 1.0

func _ready():
	spawn_enemies()

func spawn_enemies():
	for i in spawn_count:
		await get_tree().create_timer(spawn_delay * i).timeout
		var enemy = enemy_scene.instantiate()
		enemy.position = global_position + Vector2(randf_range(-30, 30), 0)
		get_parent().add_child(enemy)
