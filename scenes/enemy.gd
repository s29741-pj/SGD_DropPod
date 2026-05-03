extends CharacterBody2D

const SPEED = 60.0
const GRAVITY = 900.0
var hp = 3
var direction = 1.0
var just_turned = false

@onready var floor_detector = $FloorDetector

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	velocity.x = SPEED * direction
	floor_detector.position.x = 8 * direction

	if not just_turned:
		if is_on_wall():
			direction *= -1
			just_turned = true
		elif is_on_floor() and not floor_detector.is_colliding():
			direction *= -1
			just_turned = true
	else:
		just_turned = false

	move_and_slide()

func take_damage(amount):
	hp -= amount
	if hp <= 0:
		queue_free()
