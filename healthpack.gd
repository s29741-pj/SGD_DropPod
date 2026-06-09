extends Area2D

@onready var sfx_player = $SFXPlayer
@export var sfx_pickup: AudioStream

var heal_amount = 2

func _ready():
	body_entered.connect(_on_body_entered)
	$Sprite.play("idle")

func _on_body_entered(body):
	if body.is_in_group("player") and body.hp < body.max_hp:
		if sfx_pickup:
			sfx_player.stream = sfx_pickup
			sfx_player.play()
		body.heal(heal_amount)
		$CollisionShape2D.set_deferred("disabled", true)
		$Sprite.play("pickup")
		await $Sprite.animation_finished
		queue_free()
