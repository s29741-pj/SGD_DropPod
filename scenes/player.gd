extends CharacterBody2D

const SPEED = 180.0
const JUMP_VELOCITY = -380.0
const GRAVITY = 900.0
const FUEL_MAX = 100.0
const FUEL_REFILL = 30.0
const INVINCIBILITY_TIME = 1.0


@export var bullet_scene: PackedScene
@export var muzzle_flash_scene: PackedScene
@export var melee_hitbox_scene: PackedScene

var can_shoot = true
var fuel = FUEL_MAX
var current_weapon = 0
var weapons = ["bolt_pistol", "bolter", "plasma", "melee"]

var hp = 5
var max_hp = 5
var is_dead = false
var invincible = false
@onready var hud = get_parent().get_node("HUD")


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
	if hud:
		hud.update_hp(hp, max_hp)
		hud.update_fuel(fuel)
		hud.update_weapon(weapons[current_weapon])

		
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
	var hitbox = melee_hitbox_scene.instantiate()
	var facing = 1.0
	if velocity.x < 0:
		facing = -1.0
	hitbox.position = global_position + Vector2(20.0 * facing, 0)
	hitbox.collision_layer = 3
	hitbox.collision_mask = 2
	get_parent().add_child(hitbox)
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
		
func take_damage(amount):
	if invincible or is_dead:
		return
	hp -= amount
	invincible = true
	if hp <= 0:
		die()
	await get_tree().create_timer(INVINCIBILITY_TIME).timeout
	invincible = false

func die():
	is_dead = true
	print("GRACZ MARTWY")
	await get_tree().create_timer(1.0).timeout
	get_tree().reload_current_scene()
