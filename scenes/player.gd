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
@onready var stand_shape = $CollisionShape2D
@onready var crouch_shape = $CrouchShape

var is_crouching = false

var can_shoot = true
var fuel = FUEL_MAX
var current_weapon = 0
var weapons = ["bolter", "gatling", "knife"]

var hp = 5
var max_hp = 5
var is_dead = false
var invincible = false
@onready var hud = get_parent().get_node("HUD")

var ammo = {
	"bolter": 30,
	"gatling": 100
}
var max_ammo = {
	"bolter": 30,
	"gatling": 100
}

var heat = 0.0
var max_heat = 100.0
var is_overheated = false
var gatling_cooldown = false
const HEAT_PER_SHOT = 8.0
const HEAT_DISSIPATION = 15.0
const OVERHEAT_COOLDOWN = 3.0

var combo_count = 0
var combo_timer = 0.0
var bolter_mode = "burst"

const COMBO_WINDOW = 0.8

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Zwykły skok
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Jetpack / powerjump
	if Input.is_action_just_pressed("jetpack") and not is_on_floor() and fuel > 30:
		velocity.y = JUMP_VELOCITY * 0.9
		fuel -= 30.0
	
	# Kucnięcie
	if Input.is_action_pressed("crouch") and is_on_floor():
		# Na razie tylko print, dodamy CollisionShape później
		print("KUCANIE")

	if is_on_floor():
		fuel = min(fuel + FUEL_REFILL * delta, FUEL_MAX)
 
	var direction = Input.get_axis("ui_left", "ui_right")
	if direction != 0:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	if Input.is_action_just_pressed("switch_weapon"):
		current_weapon = (current_weapon + 1) % weapons.size()
		print("Bron: ", weapons[current_weapon])
		
	# Kucnięcie
	if Input.is_action_pressed("crouch") and is_on_floor():
		is_crouching = true
		stand_shape.disabled = true
		crouch_shape.disabled = false
		velocity.x *= 0.5
	else:
		is_crouching = false
		stand_shape.disabled = false
		crouch_shape.disabled = true

# Przełączanie trybu boltera
	if Input.is_action_just_pressed("secondary_fire") and weapons[current_weapon] == "bolter":
		if bolter_mode == "burst":
			bolter_mode = "auto"
		else:
			bolter_mode = "burst"
		print("Bolter: ", bolter_mode)

	# Ogień ciągły boltera
	if Input.is_action_pressed("ui_primary") and weapons[current_weapon] == "gatling":
		shoot()
	elif Input.is_action_pressed("ui_primary") and weapons[current_weapon] == "bolter" and bolter_mode == "auto":
		shoot()
	elif Input.is_action_just_pressed("ui_primary") and weapons[current_weapon] == "bolter" and bolter_mode == "burst":
		shoot()
	elif Input.is_action_just_pressed("ui_primary") and weapons[current_weapon] == "knife":
		shoot()
		
	if hud:
		hud.update_score(GameManager.score)
		hud.update_hp(hp, max_hp)
		hud.update_fuel(fuel)
		hud.update_heat(heat)
		var current_ammo = ammo.get(weapons[current_weapon], -1)
		if weapons[current_weapon] == "bolter":
			hud.update_weapon("bolter", bolter_mode, current_ammo)
		else:
			hud.update_weapon(weapons[current_weapon], "", current_ammo)

	if weapons[current_weapon] != "gatling" or not Input.is_action_pressed("ui_primary"):
		if not is_overheated:
			heat = max(heat - HEAT_DISSIPATION * delta, 0.0)
	
	# Combo timer
	if combo_timer > 0:
		combo_timer -= delta
	if combo_timer <= 0 and combo_count > 0:
		combo_count = 0
			
	move_and_slide()

	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if collision == null:
			continue
		var collider = collision.get_collider()
		if collider == null:
			continue
		if collider.is_in_group("enemy") and not invincible:
			take_damage(1)

func shoot():
	if not can_shoot:
		return
	match weapons[current_weapon]:
		"bolter":
			if bolter_mode == "burst":
				fire_bolter()
			else:
				fire_bolter_auto()
		"gatling":
			fire_gatling()
		"knife":
			fire_melee()
			

func fire_gatling():
	if is_overheated or ammo["gatling"] <= 0:
		return
	if gatling_cooldown:
		return
	gatling_cooldown = true
	ammo["gatling"] -= 1
	heat += max(2.0, HEAT_PER_SHOT - GameManager.upgrades["gatling_heat"] * 1.5)
	spawn_bullet(0.7)
	if heat >= max_heat:
		is_overheated = true
		heat = max_heat
		await get_tree().create_timer(OVERHEAT_COOLDOWN).timeout
		is_overheated = false
		heat = 0.0
	await get_tree().create_timer(max(0.03, 0.08 - GameManager.upgrades["gatling_fire_rate"] * 0.01)).timeout
	gatling_cooldown = false

func fire_bolter():
	var cost = 3
	if ammo["bolter"] < cost:
		print("BRAK AMUNICJI")
		return
	can_shoot = false
	for i in 3:
		ammo["bolter"] -= 1
		spawn_bullet(1.0 + GameManager.upgrades["bolter_damage"] * 0.5)
		await get_tree().create_timer(0.1 - GameManager.upgrades["bolter_fire_rate"] * 0.015).timeout
	await get_tree().create_timer(0.3).timeout
	can_shoot = true

func fire_bolter_auto():
	if ammo["bolter"] <= 0:
		print("BRAK AMUNICJI")
		return
	if not can_shoot:
		return
	can_shoot = false
	ammo["bolter"] -= 1
	spawn_bullet(1.0 + GameManager.upgrades["bolter_damage"] * 0.5)
	await get_tree().create_timer(max(0.05, 0.15 - GameManager.upgrades["bolter_fire_rate"] * 0.02)).timeout
	can_shoot = true
	
func fire_melee():
	can_shoot = false
	combo_count += 1
	combo_timer = COMBO_WINDOW

	var hitbox = melee_hitbox_scene.instantiate()
	var facing = 1.0
	if velocity.x < 0:
		facing = -1.0

	if combo_count == 1:
		# Zwykły atak
		hitbox.position = global_position + Vector2(20.0 * facing, 0)
		hitbox.get_node("CollisionShape2D").shape.size = Vector2(24, 20)
		print("ATAK 1")
	elif combo_count == 2:
		# Mocniejszy atak
		hitbox.position = global_position + Vector2(24.0 * facing, 0)
		hitbox.get_node("CollisionShape2D").shape.size = Vector2(28, 24)
		print("ATAK 2")
	elif combo_count >= 3:
		# Finisher
		hitbox.position = global_position + Vector2(28.0 * facing, -8)
		hitbox.get_node("CollisionShape2D").shape.size = Vector2(32, 32)
		combo_count = 0
		combo_timer = 0.0
		print("FINISHER!")

	hitbox.collision_layer = 3
	hitbox.collision_mask = 2
	get_parent().add_child(hitbox)

	# Obrażenia rosną z combo
	if combo_count == 0:
		hitbox.damage = 4
	elif combo_count == 2:
		hitbox.damage = 2
	else:
		hitbox.damage = 1

	await get_tree().create_timer(0.3).timeout
	can_shoot = true

func spawn_bullet(size_mult):
	var bullet = bullet_scene.instantiate()
	var shoot_direction = (get_global_mouse_position() - global_position).normalized()
	bullet.position = global_position + shoot_direction * 30
	bullet.direction = shoot_direction
	bullet.scale = Vector2(size_mult, size_mult)
	bullet.collision_layer = 3
	bullet.collision_mask = 2
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
	await get_tree().create_timer(1.0).timeout
	get_tree().get_root().get_child(0).get_node("GameOverScreen").show_game_over()
	
func heal(amount):
	hp = min(hp + amount, max_hp)

func pickup_ammo(amount):
	var current = weapons[current_weapon]
	if current in ammo:
		ammo[current] = min(ammo[current] + amount, max_ammo[current])
		
		
func apply_upgrades():
	max_hp += GameManager.upgrades["max_hp"] * 2
	hp = max_hp
	max_ammo["bolter"] += GameManager.upgrades["max_ammo"] * 10
	ammo["bolter"] = max_ammo["bolter"]
	max_ammo["gatling"] += GameManager.upgrades["max_ammo"] * 20
	ammo["gatling"] = max_ammo["gatling"]
	
func _ready():
	apply_upgrades()
	set_collision_layer_value(3, false)
