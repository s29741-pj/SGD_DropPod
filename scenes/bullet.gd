extends Area2D

const SPEED = 600.0
var direction = Vector2.ZERO

func _ready():
	body_entered.connect(_on_body_entered)
	await get_tree().create_timer(2.0).timeout
	if is_inside_tree():
		queue_free()

func _process(delta):
	position += direction * SPEED * delta

func _on_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage(1)
	queue_free()
