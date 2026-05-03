extends Area2D

const SPEED = 600.0
var direction = Vector2.ZERO

func _ready():
	# Usuń pocisk po 2 sekundach
	await get_tree().create_timer(2.0).timeout
	queue_free()

func _process(delta):
	position += direction * SPEED * delta
