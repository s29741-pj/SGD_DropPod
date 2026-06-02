extends CharacterBody2D

const GRAVITY = 900.0
const SHOOT_COOLDOWN = 0.2
const BARREL_OFFSET = 15.0
const BOB_SPEED = 1.5
const BOB_AMPLITUDE = 30.0
var hp = 16
var can_shoot = true
var player_ref = null
var is_hurt = false
var time = 0.0

@onready var upper_body = $UpperBody
@onready var lower_body = $LowerBody
@onready var detection_area = $DetectionArea
@onready var sfx_player = $SFXPlayer

@export var sfx_shoot: AudioStream

func _ready():
	GameManager.register_enemy()
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)
	lower_body.play("idle")
	upper_body.play("shoot")

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	move_and_slide()
	
	time += delta
	var bob_rotation = sin(time * BOB_SPEED) * 0.2
	
	if player_ref:
		var dir = (player_ref.global_position - global_position).normalized()
		var angle = atan2(dir.y, dir.x)
		
		if player_ref.global_position.x < global_position.x:
			upper_body.flip_h = false
			upper_body.rotation = PI + angle - bob_rotation
		else:
			upper_body.flip_h = false
			upper_body.rotation = angle + bob_rotation
		
		if can_shoot:
			shoot()
	else:
		upper_body.flip_h = false
		upper_body.rotation = bob_rotation
			
func _on_body_entered(body):
	if body.is_in_group("player"):
		player_ref = body

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_ref = null



func shoot():
	if not player_ref:
		return
	can_shoot = false
	if sfx_shoot:
		sfx_player.stream = sfx_shoot
		sfx_player.play()
	
	var direction = (player_ref.global_position - upper_body.global_position).normalized()
	var perpendicular = Vector2(-direction.y, direction.x)
	
	# Pierwszy pocisk - lewa lufa
	var bullet1 = load("res://scenes/bullet.tscn").instantiate()
	bullet1.direction = direction
	bullet1.collision_layer = 3
	bullet1.set_collision_mask_value(1, true)
	bullet1.set_collision_mask_value(2, false)
	get_parent().add_child(bullet1)
	bullet1.global_position = upper_body.global_position + perpendicular * BARREL_OFFSET + direction * 40
	
	# Krótkie opóźnienie między lufami
	await get_tree().create_timer(0.1).timeout
	
	# Drugi pocisk - prawa lufa
	var bullet2 = load("res://scenes/bullet.tscn").instantiate()
	bullet2.direction = direction
	bullet2.collision_layer = 3
	bullet2.set_collision_mask_value(1, true)
	bullet2.set_collision_mask_value(2, false)
	get_parent().add_child(bullet2)
	bullet2.global_position = upper_body.global_position - perpendicular * BARREL_OFFSET + direction * 40
	
	await get_tree().create_timer(SHOOT_COOLDOWN).timeout
	can_shoot = true

func take_damage(amount):
	hp -= amount
	is_hurt = true
	upper_body.modulate = Color.WHITE * 2
	lower_body.modulate = Color.WHITE * 2
	await get_tree().create_timer(0.1).timeout
	if is_inside_tree():
		upper_body.modulate = Color(1, 1, 1, 1)
		lower_body.modulate = Color(1, 1, 1, 1)
		is_hurt = false
	if hp <= 0:
		var explosion = load("res://scenes/boss_explosion.tscn").instantiate()
		explosion.global_position = global_position
		get_parent().add_child(explosion)
		GameManager.enemy_died()
		queue_free()
