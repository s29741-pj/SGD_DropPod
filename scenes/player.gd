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
@onready var lower_body = $LowerBody
@onready var upper_body = $UpperBody
@onready var full_body = $FullBody
@onready var sfx_player = $SFXPlayer
@onready var sfx_player2 = $SFXPlayer2
@onready var camera = $PlayerCamera

@export var sfx_bolter: AudioStream
@export var sfx_gatling: AudioStream
@export var sfx_knife: AudioStream
@export var sfx_jump: AudioStream
@export var sfx_medpack: AudioStream
@export var sfx_ammo: AudioStream
@export var sfx_weapon_change: AudioStream
@export var sfx_punch: AudioStream
@export var sfx_step: AudioStream
@export var sfx_reload: AudioStream
@onready var hud = get_parent().get_node("HUD")
#@onready var upper_body_head = $UpperBodyHead


var in_water = false
var is_hit = false
var can_shoot = true
var fuel = FUEL_MAX
var current_weapon = 0
var weapons = ["bolter", "knife"]
var has_gatling = false
var hp = 5
var max_hp = 5
var is_dead = false
var invincible = false
var step_timer = 0.0
const STEP_INTERVAL = 0.35

var ammo = {
	"bolter": 9999,
}
var max_ammo = {
	"bolter": 9999,
}

var heat = 0.0
var max_heat = 100.0
var is_overheated = false
var gatling_cooldown = false

var bolter_magazine = 10
var bolter_magazine_max = 10
var is_reloading = false

const HEAT_PER_SHOT = 8.0
const HEAT_DISSIPATION = 15.0
const OVERHEAT_COOLDOWN = 3.0

var combo_count = 0
var combo_timer = 0.0
var bolter_mode = "burst"
var is_finishing = false
var is_victory = false

const COMBO_WINDOW = 0.8

func play_victory():
	is_victory = true
	full_body.visible = true
	lower_body.visible = false
	upper_body.visible = false
	full_body.play("victory")

func reload_bolter():
	if is_reloading or ammo["bolter"] <= 0 or bolter_magazine == bolter_magazine_max:
		return
	play_sfx(sfx_reload)
	is_reloading = true
	can_shoot = false
	#full_body.visible = true
	lower_body.visible = true
	upper_body.visible = true
	#full_body.play("reload")
	upper_body.play("reload_upper")
	#await full_body.animation_finished
	await upper_body.animation_finished
	var needed = bolter_magazine_max - bolter_magazine
	var available = min(needed, ammo["bolter"])
	bolter_magazine += available
	ammo["bolter"] -= available
	#full_body.visible = false
	lower_body.visible = true
	upper_body.visible = true
	is_reloading = false
	can_shoot = true

func play_sfx(stream: AudioStream):
	if stream:
		sfx_player.stream = stream
		sfx_player.play()

func update_animation():
	var mouse_pos = get_global_mouse_position()
	var looking_left = mouse_pos.x < global_position.x
	
	if is_hit or is_dead or is_victory:
		return
	
	if is_reloading:
		upper_body.flip_h = looking_left
		lower_body.flip_h = looking_left
		if velocity.x != 0:
			if looking_left:
				upper_body.position = Vector2(-25, -15)
				upper_body.offset = Vector2(-45, 0)
				lower_body.position = Vector2(0, 25)
			else:
				upper_body.position = Vector2(75, -20)
				upper_body.offset = Vector2(-45, 0)
				lower_body.position = Vector2(0, 25)
		else:
			if looking_left:
				upper_body.position = Vector2(-15, -20)
				upper_body.offset = Vector2(-45, 0)
				lower_body.position = Vector2(0, 25)
			else:
				upper_body.position = Vector2(45, -20)
				upper_body.offset = Vector2(-45, 0)
				lower_body.position = Vector2(0, 25)
		#if looking_left:
			#upper_body.position = Vector2(-35, -20)
			#upper_body.offset = Vector2(-45, 0)  # pivot po prawej
			#lower_body.position = Vector2(0, 25)
		#else:
			#upper_body.position = Vector2(28, -20)
			#upper_body.offset = Vector2(-45, 0)  # pivot po prawej
			#lower_body.position = Vector2(0, 25)
		#upper_body.offset = Vector2(0, 0)
		#if looking_left:
			#upper_body.rotation = PI - (mouse_pos - global_position).angle()
			#upper_body.rotation = -upper_body.rotation
		#else:
			#upper_body.rotation = (mouse_pos - global_position).angle()
		if not is_on_floor():
			lower_body.play("jump")
		elif velocity.x != 0:
			lower_body.play("run")
		else:
			lower_body.play("idle")
		return
	
	if GameManager.knife_only_mode:
		full_body.visible = false
		lower_body.visible = true
		upper_body.visible = true
		upper_body.flip_h = looking_left
		lower_body.flip_h = looking_left
	
	# Pozycje takie same jak dla knife_idle na innych levelach
		if velocity.x != 0:
			if looking_left:
				upper_body.position = Vector2(-5, -8)
			else:
				upper_body.position = Vector2(5, -8)
		else:
			if looking_left:
				upper_body.position = Vector2(10, -11)
			else:
				upper_body.position = Vector2(-10, -11)
		lower_body.position = Vector2(0, 25)
	
		if not can_shoot:
			full_body.visible = true
			lower_body.visible = false
			upper_body.visible = false
			full_body.flip_h = looking_left
			if is_finishing:
				full_body.play("knife_combo")
				full_body.position = Vector2(0, -25)
			else:
				full_body.play("knife_attack")
				full_body.position = Vector2(0, -25)
			return
		upper_body.play("knife_idle")
		if not is_on_floor():
			lower_body.play("jump")
		elif velocity.x != 0:
			lower_body.play("run")
		else:
			lower_body.play("idle")
		return
		
	
## Głowa – statyczna, tylko odbicie lustrzane
	#upper_body_head.flip_h = looking_left
	#if not can_shoot and weapons[current_weapon] == "bolter":
		#upper_body_head.play("bolter_head")
		#upper_body_head.visible = true
	#else:
		#upper_body_head.visible = false
		# Tryb walki wręcz - całościowy sprite
		
	if not can_shoot and weapons[current_weapon] == "knife":
		full_body.visible = true
		lower_body.visible = false
		upper_body.visible = false
		full_body.flip_h = looking_left
		if is_finishing:
			full_body.play("knife_combo")
			full_body.position = Vector2(0, -25)
		else:
			full_body.play("knife_attack")
			full_body.position = Vector2(0, -25)
		return
	else:
		full_body.visible = false
		lower_body.visible = true
		upper_body.visible = true
	
	# Dolna część
	if not is_on_floor():
		lower_body.play("jump")
	elif velocity.x != 0:
		lower_body.play("run")
	else:
		lower_body.play("idle")

# Górna część – animacja
	if not can_shoot and weapons[current_weapon] == "bolter":
		#upper_body.play("bolter_head")
		upper_body.play("shoot_bolter")
	elif (not can_shoot or gatling_cooldown) and weapons[current_weapon] == "gatling":
		upper_body.play("shoot_gatling")
	elif weapons[current_weapon] == "gatling":
		upper_body.play("gatling_idle")
	elif weapons[current_weapon] == "knife":
		upper_body.play("knife_idle")
	elif velocity.x != 0:
		upper_body.play("run")
	else:
		upper_body.play("idle")
	

	# Obrót za kursorem
	
	# Pozycja górnej części zależna od animacji
	match upper_body.animation:
		"idle":
			#upper_body.position = Vector2(0, -55)
			#lower_body.position = Vector2(0, -15)
			if looking_left:
				upper_body.position = Vector2(6, -25)
				lower_body.position = Vector2(0, 25)
			else:
				upper_body.position = Vector2(-6, -25)
				
		"gatling_idle":
			if velocity.x != 0:
				if looking_left:
					upper_body.position = Vector2(-20, -25)
				else:
					upper_body.position = Vector2(20, -25)
			else:
				if looking_left:
					upper_body.position = Vector2(4, -25)
				else:
					upper_body.position = Vector2(4, -25)
		
		"knife_idle":
			if velocity.x != 0:
				if looking_left:
					upper_body.position = Vector2(-5, -8)
				else:
					upper_body.position = Vector2(5, -8)
			else:
				if looking_left:
					upper_body.position = Vector2(10, -11)
				else:
					upper_body.position = Vector2(-10, -11)
		
		"run":
			upper_body.position = Vector2(0, -10)
			lower_body.position = Vector2(0, 25)
		"shoot_bolter":
			if velocity.x != 0:
				if looking_left:
					upper_body.position = Vector2(-20, -30)
					lower_body.position = Vector2(0, 25)
				else:
					upper_body.position = Vector2(20, -30)
					lower_body.position = Vector2(0, 25)
			else:
				if looking_left:
					upper_body.position = Vector2(6, -35)
					lower_body.position = Vector2(0, 25)
				else:
					upper_body.position = Vector2(-6, -35)
					
		"shoot_gatling":
			if velocity.x != 0:	
				if looking_left:
					upper_body.position = Vector2(-35, -25)
				else:
					upper_body.position = Vector2(35, -25)
			else:	
				if looking_left:
					upper_body.position = Vector2(-15, -25)
				else:
					upper_body.position = Vector2(15, -25)
					
		# Pivot obrotu boltera/gatlinga
	if upper_body.animation == "shoot_bolter":
		if looking_left:
			upper_body.offset = Vector2(-40, 0)  # pivot po prawej
		else:
			upper_body.offset = Vector2(40, 0)  # pivot po lewej
	elif upper_body.animation == "shoot_gatling":
		if looking_left:
			upper_body.offset = Vector2(-30, 0)  # pivot po prawej
		else:
			upper_body.offset = Vector2(30, 0)  # pivot po lewej
	else:
		upper_body.offset = Vector2(0, 0)




	upper_body.flip_h = looking_left
	lower_body.flip_h = looking_left
	
	if looking_left:
		upper_body.rotation = PI - (mouse_pos - global_position).angle()
		upper_body.rotation = -upper_body.rotation
	else:
		upper_body.rotation = (mouse_pos - global_position).angle()


func _physics_process(delta):
	
	hud.update_upgrades()
	
	if global_position.y > 1000:
		die()
		
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Przeładownie
	if Input.is_action_just_pressed("reload") and weapons[current_weapon] == "bolter":
		reload_bolter()
	# Zwykły skok
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		play_sfx(sfx_jump)

	# Jetpack / powerjump
	if Input.is_action_just_pressed("jetpack") and fuel > 30:
		play_sfx(sfx_jump)
		velocity.y = JUMP_VELOCITY * 0.9
		fuel -= 30.0

	if is_on_floor():
		fuel = min(fuel + FUEL_REFILL * delta, FUEL_MAX)
 
	var direction = Input.get_axis("ui_left", "ui_right")
	var speed_mult = 0.5 if in_water else 1.0
	if direction != 0:
		velocity.x = direction * SPEED * speed_mult
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	if Input.is_action_just_pressed("switch_weapon") and not GameManager.knife_only_mode:
		current_weapon = (current_weapon + 1) % weapons.size()
		play_sfx(sfx_weapon_change)
		

		
	var player_slide_count = get_slide_collision_count()
	for i in player_slide_count:
		if i >= get_slide_collision_count():
			break
		var collision = get_slide_collision(i)
		if collision == null:
			continue
		var collider = collision.get_collider()
		if collider == null:
			continue
		if collider.is_in_group("enemy") and not invincible:
			take_damage(1)
		if collider.is_in_group("enemy"):
			var enemy_above = collider.global_position.y < global_position.y - 10
			if enemy_above:
				add_collision_exception_with(collider)
				await get_tree().create_timer(0.5).timeout
				if is_instance_valid(collider):
					remove_collision_exception_with(collider)

# Przełączanie trybu boltera
	if Input.is_action_just_pressed("secondary_fire") and weapons[current_weapon] == "bolter":
		if bolter_mode == "burst":
			bolter_mode = "auto"
		else:
			bolter_mode = "burst"
		#print("Bolter: ", bolter_mode)

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
		hud.update_upgrades()
		var current_ammo = ammo.get(weapons[current_weapon], -1)
		if weapons[current_weapon] == "bolter":
			hud.update_weapon("bolter", bolter_mode, current_ammo)
		else:
			hud.update_weapon(weapons[current_weapon], "", current_ammo)
		if GameManager.knife_only_mode:
			hud.update_weapon("TYLKO NOZ", "", -1)
	if weapons[current_weapon] != "gatling" or not Input.is_action_pressed("ui_primary"):
		if not is_overheated:
			heat = max(heat - HEAT_DISSIPATION * delta, 0.0)
	
	# Combo timer
	if combo_timer > 0:
		combo_timer -= delta
	if combo_timer <= 0 and combo_count > 0:
		combo_count = 0
		
		# Kroki
	if is_on_floor() and velocity.x != 0 and not is_dead and not is_hit:
		step_timer -= delta
		if step_timer <= 0:
			play_sfx(sfx_step)
			step_timer = STEP_INTERVAL
	else:
		step_timer = 0.0
			
	move_and_slide()
	update_animation()
			
func shoot():
	if not can_shoot:
		return
	if is_reloading:
		return
	if GameManager.knife_only_mode:
		fire_melee()
		return
	match weapons[current_weapon]:
		"bolter":
			if bolter_mode == "burst":
				fire_bolter()
				camera.shake(3.0)
			else:
				fire_bolter_auto()
				camera.shake(3.0)
				
		"gatling":
			fire_gatling()
			camera.shake(2.0)
		"knife":
			fire_melee()
			

func fire_gatling():
	if is_overheated or ammo["gatling"] <= 0:
		return
	if gatling_cooldown:
		return
	play_sfx(sfx_gatling)
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
	if bolter_magazine < 3:
		reload_bolter()
		return
	can_shoot = false
	for i in 3:
		play_sfx(sfx_bolter)
		bolter_magazine -= 1
		spawn_bullet(1.0 + GameManager.upgrades["bolter_damage"] * 0.5)
		await get_tree().create_timer(0.1 - GameManager.upgrades["bolter_fire_rate"] * 0.015).timeout
	if bolter_magazine == 0:
		reload_bolter()
	await get_tree().create_timer(0.3).timeout
	can_shoot = true

func fire_bolter_auto():
	if bolter_magazine <= 0:
		reload_bolter()
		return
	if not can_shoot:
		return
	play_sfx(sfx_bolter)
	can_shoot = false
	bolter_magazine -= 1
	spawn_bullet(1.0 + GameManager.upgrades["bolter_damage"] * 0.5)
	if bolter_magazine == 0:
		reload_bolter()
	await get_tree().create_timer(max(0.05, 0.15 - GameManager.upgrades["bolter_fire_rate"] * 0.02)).timeout
	can_shoot = true
	
func fire_melee():
	#print("FIRE MELEE, can_shoot przed: ", can_shoot)
	can_shoot = false
	#print("FIRE MELEE, can_shoot po: ", can_shoot)
	combo_count += 1
	combo_timer = COMBO_WINDOW
	var hitbox = melee_hitbox_scene.instantiate()
	var facing = sign(get_global_mouse_position().x - global_position.x)
	if facing == 0:
		facing = 1.0
	if combo_count == 1:
		play_sfx(sfx_knife)
		hitbox.position = global_position + Vector2(20.0 * facing, 0)
		hitbox.get_node("CollisionShape2D").shape.size = Vector2(24, 20)
		hitbox.damage = 1
		#print("ATAK 1")
	elif combo_count == 2:
		play_sfx(sfx_knife)
		hitbox.position = global_position + Vector2(24.0 * facing, 0)
		hitbox.get_node("CollisionShape2D").shape.size = Vector2(28, 24)
		hitbox.damage = 2
		#print("ATAK 2")
	elif combo_count >= 3:
		play_sfx(sfx_knife)
		is_finishing = true
		hitbox.position = global_position + Vector2(28.0 * facing, -8)
		hitbox.get_node("CollisionShape2D").shape.size = Vector2(32, 32)
		hitbox.damage = 4
		combo_count = 0
		combo_timer = 0.0
		#print("FINISHER!")
	hitbox.collision_layer = 3
	hitbox.collision_mask = 2
	get_parent().add_child(hitbox)
	
	# Różny czas dla finishera i zwykłego ataku
	if is_finishing:
		await get_tree().create_timer(0.8).timeout
	else:
		await get_tree().create_timer(0.3).timeout
	is_finishing = false
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
	camera.shake(8.0)
	if invincible or is_dead:
		return
	hp -= amount
	is_hit = true
	invincible = true
	can_shoot = true
	is_reloading = false
	full_body.visible = true
	lower_body.visible = false
	upper_body.visible = false
	full_body.play("hit")
	play_sfx(sfx_punch)
	if hp <= 0:
		die()
		return
	await get_tree().create_timer(0.3).timeout
	is_hit = false
	full_body.visible = false
	lower_body.visible = true
	upper_body.visible = true
	await get_tree().create_timer(INVINCIBILITY_TIME).timeout
	invincible = false

func die():
	is_dead = true
	full_body.visible = true
	lower_body.visible = false
	upper_body.visible = false
	full_body.play("death")
	await full_body.animation_finished
	await get_tree().create_timer(0.5).timeout
	if GameManager.has_checkpoint() and GameManager.checkpoint_data.has("level"):
		get_tree().change_scene_to_file(GameManager.checkpoint_data["level"])
	else:
		get_tree().current_scene.get_node("GameOverScreen").show_game_over()
	
func heal(amount):
	hp = min(hp + amount, max_hp)

func pickup_ammo(amount):
	var current = weapons[current_weapon]
	if current in ammo:
		ammo[current] = min(ammo[current] + amount, max_ammo[current])
		

func pickup_gatling():
	has_gatling = true
	weapons = ["bolter", "gatling", "knife"]
	ammo["gatling"] = 100
	max_ammo["gatling"] = 100
	
	
func apply_upgrades():
	max_hp += GameManager.upgrades["max_hp"] * 2
	hp = max_hp
	max_ammo["bolter"] += GameManager.upgrades["max_ammo"] * 10
	ammo["bolter"] = max_ammo["bolter"]
	if has_gatling:
		max_ammo["gatling"] += GameManager.upgrades["max_ammo"] * 20
		ammo["gatling"] = max_ammo["gatling"]
	
func _ready():
	apply_upgrades()
	if GameManager.knife_only_mode:
		#current_weapon = weapons.find("knife")
		current_weapon = 1
	if GameManager.has_checkpoint() and GameManager.checkpoint_data.has("player_x"):
		var data = GameManager.checkpoint_data
		hp = data.get("hp", max_hp)
		ammo["bolter"] = data.get("ammo_bolter", max_ammo["bolter"])
		if data.get("has_gatling", false):
			pickup_gatling()
			ammo["gatling"] = data.get("ammo_gatling", 100)
		global_position = Vector2(data["player_x"], data["player_y"])
