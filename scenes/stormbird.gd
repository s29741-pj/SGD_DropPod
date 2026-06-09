extends Area2D

@onready var sprite = $Sprite
@onready var sfx_player = $SFXPlayer
@export var sfx_engine: AudioStream

func _ready():
	body_entered.connect(_on_body_entered)
	sprite.play("idle")
	if sfx_engine:
		sfx_player.stream = sfx_engine
		sfx_player.play()

func _on_body_entered(body):
	if body.is_in_group("player"):
		await get_tree().create_timer(1.5).timeout
		#GameManager.advance_level()
		GameManager.level_completed.emit()

#TU STOP
#Dodaj instancję stormbird.tscn do level1.tscn, level2.tscn i level4.tscn na końcu każdego poziomu – zastąpi obecną extraction_zone.tscn.
