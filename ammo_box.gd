extends Area2D

@onready var sfx_player = $SFXPlayer
@export var sfx_pickup: AudioStream
var ammo_amount = 10

func _ready():
	body_entered.connect(_on_body_entered)
	$Sprite.play("idle")

func _on_body_entered(body):
	if body.is_in_group("player"):
		var current = body.weapons[body.current_weapon]
		if current in body.ammo:
			if body.ammo[current] < body.max_ammo[current]:
				if sfx_pickup:
					sfx_player.stream = sfx_pickup
					sfx_player.play()
				body.pickup_ammo(ammo_amount)
				$CollisionShape2D.set_deferred("disabled", true)
				$Sprite.play("pickup")
				await $Sprite.animation_finished
				await get_tree().create_timer(0.5).timeout
				queue_free()
				
			
