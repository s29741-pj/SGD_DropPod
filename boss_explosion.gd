extends Node2D

func _ready():
	#print("EKSPLOZJA GOTOWA")
	$Explosion1.position = Vector2(-80, -40)
	$Explosion2.position = Vector2(0, 0)
	$Explosion3.position = Vector2(80, -40)
	
	$Explosion1.play("explode")
	#print("E1 animacja: ", $Explosion1.animation, " klatka: ", $Explosion1.frame)
	await get_tree().create_timer(0.2).timeout
	$Explosion2.play("explode")
	await get_tree().create_timer(0.2).timeout
	$Explosion3.play("explode")
	
	await $Explosion3.animation_finished
	queue_free()
