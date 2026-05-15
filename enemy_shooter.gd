extends CharacterBody2D

const SPEED_PATROL = 40.0
const SPEED_CHASE = 90.0
const GRAVITY = 900.0
const SHOOT_COOLDOWN = 2.0
const PREFERRED_DISTANCE = 120.0
var hp = 2
var direction = 1.0
var just_turned = false
var can_shoot = true
var is_chasing = false
var player_ref = null

@onready var floor_detector = $FloorDetector
@onready var detection_area = $DetectionArea

func _ready():
	GameManager.register_enemy()
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	if is_chasing and player_ref:
		var dist = global_position.distance_to(player_ref.global_position)
		if dist > PREFERRED_DISTANCE:
			# Zbliż się do gracza
			direction = sign(player_ref.global_position.x - global_position.x)
			velocity.x = SPEED_CHASE * direction
		else:
			# Stój i strzelaj
			velocity.x = move_toward(velocity.x, 0, SPEED_CHASE)
			if can_shoot:
				shoot()
	else:
		velocity.x = SPEED_PATROL * direction
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

func _on_body_entered(body):
	if body.is_in_group("player"):
		is_chasing = true
		player_ref = body

func _on_body_exited(body):
	if body.is_in_group("player"):
		is_chasing = false
		player_ref = null

func shoot():
	can_shoot = false
	var bullet = load("res://scenes/bullet.tscn").instantiate()
	var direction_to_player = (player_ref.dglobal_position - global_position).normalized()
	bullet.position = global_position + direction_to_player * 20
	bullet.direction = direction_to_player
	bullet.collision_layer = 3
	bullet.collision_mask = 1
	get_parent().add_child(bullet)
	await get_tree().create_timer(SHOOT_COOLDOWN).timeout
	can_shoot = true

func take_damage(amount):
	hp -= amount
	$ColorRect.color = Color.WHITE
	await get_tree().create_timer(0.1).timeout
	if is_inside_tree():
		$ColorRect.color = Color(1.0, 0.4, 0.0)
	if hp <= 0:
		GameManager.enemy_died()
		queue_free()
