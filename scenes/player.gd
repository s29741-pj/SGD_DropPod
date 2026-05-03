extends CharacterBody2D

const SPEED = 180.0
const JUMP_VELOCITY = -380.0
const GRAVITY = 900.0
const FUEL_MAX = 100.0
const FUEL_REFILL = 30.0

@export var bullet_scene: PackedScene
@export var muzzle_flash_scene: PackedScene

var can_shoot = true
var fuel = FUEL_MAX
var current_weapon = 0
var weapons = ["bolt_pistol", "bolter", "plasma", "melee"]


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

	if Input.is_action_just_pressed("switch_weapon"):
		current_weapon = (current_weapon + 1) % weapons.size()
		print("Bron: ", weapons[current_weapon])

	move_and_slide()

func shoot():
	if not can_shoot:
		return
	match weapons[current_weapon]:
		"bolt_pistol":
			fire_bolt_pistol()
		"bolter":
			fire_bolter()
		"plasma":
			fire_plasma()
		"melee":
			fire_melee()
			
			
func fire_bolt_pistol():
	can_shoot = false
	spawn_bullet(1.0)
	await get_tree().create_timer(0.4).timeout
	can_shoot = true
	
func fire_bolter():
	can_shoot = false
	for i in 3:
		spawn_bullet(1.0)
		await get_tree().create_timer(0.1).timeout
	await get_tree().create_timer(0.3).timeout
	can_shoot = true

func fire_plasma():
	can_shoot = false
	spawn_bullet(3.0)
	await get_tree().create_timer(0.8).timeout
	can_shoot = true

func fire_melee():
	can_shoot = false
	print("ATAK WRECZEM")
	await get_tree().create_timer(0.4).timeout
	can_shoot = true

func spawn_bullet(size_mult):
	var bullet = bullet_scene.instantiate()
	bullet.position = global_position
	bullet.direction = (get_global_mouse_position() - global_position).normalized()
	bullet.scale = Vector2(size_mult, size_mult)
	get_parent().add_child(bullet)
	if muzzle_flash_scene:
		var flash = muzzle_flash_scene.instantiate()
		flash.position = global_position
		get_parent().add_child(flash)
