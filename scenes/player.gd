extends CharacterBody2D

const SPEED = 180.0
const JUMP_VELOCITY = -380.0
const GRAVITY = 900.0
const JETPACK_FORCE = -600.0
const FUEL_MAX = 100.0
const FUEL_DRAIN = 40.0
const FUEL_REFILL = 30.0

var fuel = FUEL_MAX

func _physics_process(delta):
	# Grawitacja
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Skok z podłogi
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Jetpack w powietrzu
	#if Input.is_action_pressed("ui_accept") and not is_on_floor() and fuel > 0:
		#velocity.y += JETPACK_FORCE * delta
		#fuel -= FUEL_DRAIN * delta

	# Jetpack – impulsowy
	if Input.is_action_just_pressed("ui_accept") and not is_on_floor() and fuel > 30:
		velocity.y = JUMP_VELOCITY * 0.7
		fuel -= 30.0
		
	# Uzupełnianie paliwa na podłodze
	if is_on_floor():
		fuel = min(fuel + FUEL_REFILL * delta, FUEL_MAX)

	# Ruch lewo/prawo
	var direction = Input.get_axis("ui_left", "ui_right")
	if direction != 0:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	print(snappedf(fuel, 0.1))
