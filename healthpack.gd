extends Area2D

var heal_amount = 2

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.has_method("heal"):
		if body.hp < body.max_hp:
			body.heal(heal_amount)
			queue_free()
