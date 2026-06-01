extends Area2D

@onready var sfx_player = $SFXPlayer
@export var sfx_pickup: AudioStream

func _ready():
	body_entered.connect(_on_body_entered)
	$Sprite.play("idle")

func _on_body_entered(body):
	if body.is_in_group("player") and not body.has_gatling:
		if sfx_pickup:
			sfx_player.stream = sfx_pickup
			sfx_player.play()
		body.pickup_gatling()
		$CollisionShape2D.disabled = true
		$Sprite.play("pickup")
		await $Sprite.animation_finished
		await get_tree().create_timer(0.5).timeout
		queue_free()
