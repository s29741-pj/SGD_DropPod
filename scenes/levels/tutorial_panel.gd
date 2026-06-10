extends CanvasLayer

func _ready():
	get_tree().paused = true
	$Button.pressed.connect(_on_close_pressed)

func _on_close_pressed():
	get_tree().paused = false
	queue_free()
