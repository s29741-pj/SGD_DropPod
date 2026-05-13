extends CanvasLayer

@onready var hp_bar = $VBoxContainer/HBoxContainer_HP/HPBar
@onready var fuel_bar = $VBoxContainer/HBoxContainer_JET/FuelBar
@onready var weapon_label = $VBoxContainer/WeaponLabel

func update_hp(value, max_value):
	hp_bar.max_value = max_value
	hp_bar.value = value

func update_fuel(value):
	fuel_bar.value = value

func update_weapon(weapon_name):
	weapon_label.text = weapon_name.to_upper()

func update_ammo(current_ammo, weapon_name):
	if weapon_name in ["bolter", "bolt_pistol", "plasma"]:
		weapon_label.text = weapon_name.to_upper() + " | " + str(current_ammo)
	else:
		weapon_label.text = weapon_name.to_upper()
