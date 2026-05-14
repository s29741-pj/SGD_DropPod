extends Area2D

var damage = 1

func _ready():
	body_entered.connect(_on_body_entered)
	await get_tree().create_timer(0.15).timeout
	queue_free()

func _on_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage(damage)
