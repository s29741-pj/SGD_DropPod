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
var is_hurt = false
var is_dead_anim = false
var is_attacking = false

@onready var sprite = $Sprite

@onready var floor_detector = $FloorDetector
@onready var detection_area = $DetectionArea
const JUMP_VELOCITY = -260.0

func update_animation():
	if is_dead_anim or is_hurt:
		if player_ref:
			sprite.flip_h = player_ref.global_position.x < global_position.x
		return
	if is_attacking:
		if sprite.animation != "o3_shot":
			sprite.play("o3_shot")
		if player_ref:
			sprite.flip_h = player_ref.global_position.x < global_position.x
		return
	if is_chasing and player_ref:
		if sprite.animation != "o3_walk":
			sprite.play("o3_walk")
	else:
		if sprite.animation != "o3_idle":
			sprite.play("o3_idle")
	if player_ref:
		sprite.flip_h = player_ref.global_position.x < global_position.x

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
			direction = sign(player_ref.global_position.x - global_position.x)
			velocity.x = SPEED_CHASE * direction
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED_CHASE)
			if can_shoot:
				shoot()
		# Skocz tylko gdy gracz jest wyżej
		var player_above = player_ref.global_position.y < global_position.y - 32
		if player_above and is_on_floor():
			velocity.y = JUMP_VELOCITY
		# Skocz przy ścianie tylko gdy to nie jest gracz
		if is_on_wall() and is_on_floor():
			var wall_collision = get_slide_collision(0)
			if wall_collision and not wall_collision.get_collider().is_in_group("player"):
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
	update_animation()
	
		# Zapobiegaj wskakiwaniu na gracza
	for i in get_slide_collision_count():
		if i >= get_slide_collision_count():
			break
		var collision = get_slide_collision(i)
		if collision == null:
			continue
		var collider = collision.get_collider()
		if collider == null:
			continue
		if collider.is_in_group("player"):
			# Odepchnij wroga w bok od gracza
			var push_dir = sign(global_position.x - collider.global_position.x)
			if push_dir == 0:
				push_dir = 1
			velocity.x = push_dir * SPEED_CHASE * 2

func _on_body_entered(body):
	if body.is_in_group("player"):
		is_chasing = true
		player_ref = body
		# Zapamiętaj kierunek do gracza
		direction = sign(player_ref.global_position.x - global_position.x)

func _on_body_exited(body):
	if body.is_in_group("player"):
		# Nie resetuj is_chasing – shooter pamięta kierunek
		player_ref = null


func shoot():
	can_shoot = false
	is_attacking = true
	var bullet = load("res://scenes/bullet.tscn").instantiate()
	var direction_to_player = (player_ref.global_position - global_position).normalized()
	bullet.position = global_position + direction_to_player * 20
	bullet.direction = direction_to_player
	bullet.collision_layer = 3
	bullet.collision_mask = 1
	get_parent().add_child(bullet)
	sprite.play("o3_shot")
	await get_tree().create_timer(SHOOT_COOLDOWN).timeout
	is_attacking = false
	can_shoot = true

func take_damage(amount):
	hp -= amount
	is_hurt = true
	sprite.play("o3_hit")
	if hp <= 0:
		await get_tree().create_timer(0.15).timeout
		if not is_inside_tree():
			return
		is_hurt = false
		is_dead_anim = true
		sprite.play("o3_death")
		await get_tree().create_timer(0.8).timeout
		GameManager.enemy_died()
		queue_free()
		return
	await get_tree().create_timer(0.2).timeout
	is_hurt = false
