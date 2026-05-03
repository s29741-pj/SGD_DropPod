extends CharacterBody2D

@export var bullet_scene: PackedScene
@export var muzzle_flash_scene: PackedScene

const SPEED = 180.0
const JUMP_VELOCITY = -380.0
const GRAVITY = 900.0
const JETPACK_FORCE = -600.0
const FUEL_MAX = 100.0
const FUEL_DRAIN = 40.0
const FUEL_REFILL = 30.0
   

var can_shoot = true
const SHOOT_COOLDOWN = 0.3
var fuel = FUEL_MAX

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	if Input.is_action_just_pressed("ui_accept") and not is_on_floor() and fuel > 30:
		velocity.y = JUMP_VELOCITY * 0.7
		fuel -= 30.0

	if is_on_floor():
		fuel = min(fuel + FUEL_REFILL * delta, FUEL_MAX)

	var direction = Input.get_axis("ui_left", "ui_right")
	if direction != 0:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	if Input.is_action_just_pressed("ui_primary"):
		shoot()

	move_and_slide()

func shoot():
	if not can_shoot:
		return
	can_shoot = false
	var bullet = bullet_scene.instantiate()
	bullet.position = global_position
	bullet.direction = (get_global_mouse_position() - global_position).normalized()
	get_parent().add_child(bullet)
	var flash = muzzle_flash_scene.instantiate()
	flash.position = global_position
	get_parent().add_child(flash)
	await get_tree().create_timer(SHOOT_COOLDOWN).timeout
	can_shoot = true
