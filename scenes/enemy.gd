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
var is_hurt = false
var is_dead_anim = false
var is_attacking = false

@onready var floor_detector = $FloorDetector
@onready var detection_area = $DetectionArea
@onready var sprite = $Sprite
const JUMP_VELOCITY = -280.0


func update_animation():
	if is_dead_anim or is_hurt or is_attacking:
		if player_ref:
			sprite.flip_h = player_ref.global_position.x < global_position.x
		return
	
	sprite.play("o1_walk")
	
	if player_ref:
		sprite.flip_h = player_ref.global_position.x < global_position.x
	else:
		sprite.flip_h = direction < 0
	
	sprite.position = Vector2(0, -90)
		
	#match sprite.animation:
			#"o1_idle":
				#sprite.position = Vector2(0, -90)
			#"o1_walk":
				#sprite.position = Vector2(0, 0)
			#"o1_atk":
				#if player_ref:
					#if player_ref.global_position.x > global_position.x:d
						#sprite.position = Vector2(10, 0)
					#else:
						#sprite.position = Vector2(-10, 0)
			#"o1_hit":
				#sprite.position = Vector2(0, 0)
			#"o1_death":
				#sprite.position = Vector2(0, 0)


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
			is_attacking = true
			sprite.play("o1_atk")
			await get_tree().create_timer(1.0).timeout
			damage_cooldown = false
			is_attacking = false

func _on_body_entered(body):
	print("ENEMY WYKRYL: ", body.name, " grupa: ", body.get_groups())
	if body.is_in_group("player"):
		is_chasing = true
		player_ref = body
		print("IS_CHASING USTAWIONE NA TRUE")


func _on_body_exited(body):
	if body.is_in_group("player"):
		is_chasing = false
		player_ref = null


func take_damage(amount):
	hp -= amount
	is_hurt = true
	sprite.play("o1_hit")
	await get_tree().create_timer(0.15).timeout
	is_hurt = false
	if not is_inside_tree():
		return
	if hp <= 0:
		is_dead_anim = true
		sprite.play("o1_death")
		await get_tree().create_timer(0.7).timeout
		GameManager.enemy_died()
		queue_free()
