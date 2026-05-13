extends CharacterBody2D

const SPEED = 60.0
const GRAVITY = 900.0
var hp = 3
var direction = 1.0
var just_turned = false
var damage_cooldown = false

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
	
	# Sprawdź kolizję z graczem po move_and_slide
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if collision == null:
			continue
		var collider = collision.get_collider()
		if collider == null:
			continue
		if collider.has_method("take_damage") and not damage_cooldown:
			collider.take_damage(1)
			damage_cooldown = true
			await get_tree().create_timer(1.0).timeout
			damage_cooldown = false

func _ready():
	GameManager.register_enemy()

func take_damage(amount):
	hp -= amount
	if hp <= 0:
		GameManager.enemy_died()
		queue_free()
