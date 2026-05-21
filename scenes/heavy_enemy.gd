extends CharacterBody2D

const SPEED_PATROL = 35.0
const SPEED_CHASE = 70.0
const GRAVITY = 900.0
var hp = 8
var direction = 1.0
var just_turned = false
var damage_cooldown = false
var is_chasing = false
var player_ref = null
var is_hurt = false
var is_dead_anim = false
var is_attacking = false

@onready var sprite = $Sprite
@onready var floor_detector = $FloorDetector
@onready var detection_area = $DetectionArea
const JUMP_VELOCITY = -200.0

func _ready():
	GameManager.register_enemy()
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)
	detection_area.body_entered.connect(func(b): print("HEAVY WYKRYL: ", b.name))

func _physics_process(delta):	
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	if is_attacking:
		velocity.x = move_toward(velocity.x, 0, SPEED_CHASE)
	elif is_chasing and player_ref:
		direction = sign(player_ref.global_position.x - global_position.x)
		velocity.x = SPEED_CHASE * direction
		var player_above = player_ref.global_position.y < global_position.y - 32
		if player_above and is_on_floor():
			velocity.y = JUMP_VELOCITY
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
		if collider.has_method("take_damage") and not damage_cooldown and collider.is_in_group("player"):
			collider.take_damage(2)
			damage_cooldown = true
			is_attacking = true
			await get_tree().create_timer(1.5).timeout
			damage_cooldown = false
			is_attacking = false

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
	is_hurt = true
	sprite.play("o2_hit")
	if hp <= 0:
		await get_tree().create_timer(0.15).timeout
		if not is_inside_tree():
			return
		is_hurt = false
		is_dead_anim = true
		sprite.play("o2_death")
		await get_tree().create_timer(0.8).timeout
		GameManager.enemy_died()
		queue_free()
		return
	await get_tree().create_timer(0.2).timeout
	is_hurt = false

func update_animation():
	if is_dead_anim or is_hurt:
		return
	if is_attacking:
		if sprite.animation != "o2_atk":
			sprite.play("o2_atk")
		return
	if is_chasing and player_ref:
		if sprite.animation != "o2_wlk":
			sprite.play("o2_wlk")
		# Flip tylko gdy wystarczająco daleko
		var dist = abs(player_ref.global_position.x - global_position.x)
		if dist > 5:
			sprite.flip_h = player_ref.global_position.x < global_position.x
	else:
		if sprite.animation != "o2_idle":
			sprite.play("o2_idle")
