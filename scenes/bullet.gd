extends Area2D

const SPEED = 600.0
var direction = Vector2.ZERO
var initialized = false

func _ready():
	body_entered.connect(_on_body_entered)
	await get_tree().create_timer(2.0).timeout
	if is_inside_tree():
		queue_free()

func _process(delta):
	if not initialized:
		$RayCast2D.target_position = direction * 20
		initialized = true
	
	position += direction * SPEED * delta
	
	if $RayCast2D.is_colliding():
		queue_free()

func _on_body_entered(body):
	print("POCISK TRAFIL: ", body.name)
	if body.has_method("take_damage"):
		body.take_damage(1)
	queue_free()

func _on_area_entered(area):
	queue_free()
