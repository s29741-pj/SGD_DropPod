extends AnimatedSprite2D

func _ready():
	print("SPRITE ANIMACJA: ", sprite_frames.get_animation_names())
	play("default")
	print("GRA: ", is_playing(), " animacja: ", animation)
