extends Node2D

@onready var sprite = $Sprite
@onready var sfx_player = $SFXPlayer
@onready var sfx_impact = $SFXPlayerImpact
@export var sfx_land: AudioStream
@export var sfx_impact_sound: AudioStream

signal landing_complete

var landing_speed = 300.0
var target_y = 0.0
var is_landing = false
var impact_played = false

func _ready():
	visible = false
	target_y = position.y + 400
	await get_tree().create_timer(0.5).timeout
	visible = true
	is_landing = true
	sprite.play("land")
	if sfx_land:
		sfx_player.stream = sfx_land
		sfx_player.play()
	sprite.animation_finished.connect(_on_animation_finished)

func _process(delta):
	if is_landing and position.y < target_y:
		position.y += landing_speed * delta
	elif is_landing and not impact_played:
		impact_played = true
		is_landing = false
		sfx_player.stop()
		if sfx_impact_sound:
			sfx_impact.stream = sfx_impact_sound
			sfx_impact.play()

func _on_animation_finished():
	await get_tree().create_timer(1.0).timeout
	landing_complete.emit()
