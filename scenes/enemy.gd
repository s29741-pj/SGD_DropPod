extends CharacterBody2D

const SPEED_PATROL = 60.0
const SPEED_CHASE = 120.0
const GRAVITY = 900.0
var hp = 3
var direction = 1.0
var just_turned = false
var damage_cooldown = false
var is_chasing = false
var player_ref = null

@onready var floor_detector = $FloorDetector
@onready var detection_area = $DetectionArea
const JUMP_VELOCITY = -280.0

func _ready():
	GameManager.register_enemy()
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	if is_chasing and player_ref:
		direction = sign(player_ref.global_position.x - global_position.x)
		velocity.x = SPEED_CHASE * direction
		# Skocz gdy gracz jest wyżej i wróg stoi na podłodze
		var player_above = player_ref.global_position.y < global_position.y - 32
		if player_above and is_on_floor():
			velocity.y = JUMP_VELOCITY
		# Skocz gdy napotka ścianę
		if is_on_wall() and is_on_floor():
			velocity.y = JUMP_VELOCITY
	else:
		velocity.x = SPEED_PATROL * direction
		floor_detector.position.x = 8 * direction
		if not just_turned:
			if is_on_wall() and is_on_floor():
				velocity.y = JUMP_VELOCITY
				direction *= -1
				just_turned = true
			elif is_on_floor() and not floor_detector.is_colliding():
				direction *= -1
				just_turned = true
		else:
			just_turned = false

	move_and_slide()

	var slide_count = get_slide_collision_count()
	for i in slide_count:
		if i >= get_slide_collision_count():
			break
		var collision = get_slide_collision(i)
		if collision == null:
			continue
		var collider = collision.get_collider()
		if collider == null:
			continue
		if collider.has_method("take_damage") and not damage_cooldown and collider.is_in_group("player"):
			collider.take_damage(1)
			damage_cooldown = true
			await get_tree().create_timer(1.0).timeout
			damage_cooldown = false

func _on_body_entered(body):
	if body.is_in_group("player"):
		is_chasing = true
		player_ref = body


func _on_body_exited(body):
	if body.is_in_group("player"):
		is_chasing = false
		player_ref = null


func take_damage(amount):
	hp -= amount
	$ColorRect.color = Color.WHITE
	await get_tree().create_timer(0.1).timeout
	if is_inside_tree():
		$ColorRect.color = Color(0.81, 0.21, 0.36)
	if hp <= 0:
		GameManager.enemy_died()
		queue_free()
