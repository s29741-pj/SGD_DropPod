extends CharacterBody2D

const SPEED = 40.0
const GRAVITY = 900.0
const SHOOT_COOLDOWN = 2.0
var hp = 2
var direction = 1.0
var just_turned = false
var can_shoot = true
var player_in_range = false
var player_ref = null

@onready var detection_area = $DetectionArea
@onready var floor_detector = $FloorDetector

func _ready():
	GameManager.register_enemy()
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)

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

	if player_in_range and can_shoot and player_ref:
		shoot()

func _on_body_entered(body):
	if body.has_method("take_damage"):
		player_in_range = true
		player_ref = body

func _on_body_exited(body):
	if body.has_method("take_damage"):
		player_in_range = false
		player_ref = null

func shoot():
	can_shoot = false
	var bullet = load("res://scenes/bullet.tscn").instantiate()
	var direction_to_player = (player_ref.global_position - global_position).normalized()
	bullet.position = global_position + direction_to_player * 20
	bullet.direction = direction_to_player
	bullet.collision_layer = 3
	bullet.collision_mask = 1
	get_parent().add_child(bullet)
	await get_tree().create_timer(SHOOT_COOLDOWN).timeout
	can_shoot = true

func take_damage(amount):
	hp -= amount
	# Flash
	$ColorRect.color = Color.WHITE
	await get_tree().create_timer(0.1).timeout
	if is_inside_tree():
		$ColorRect.color = Color(1.0, 0.4, 0.0) # oryginalny kolor
	if hp <= 0:
		GameManager.enemy_died()
		queue_free()
