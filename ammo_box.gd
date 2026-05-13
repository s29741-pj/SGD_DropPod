extends Area2D

var ammo_amount = 10

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.has_method("pickup_ammo"):
		var current = body.weapons[body.current_weapon]
		if current in body.ammo:
			if body.ammo[current] < body.max_ammo[current]:
				body.pickup_ammo(ammo_amount)
				queue_free()
