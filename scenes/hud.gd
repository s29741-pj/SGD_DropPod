extends CanvasLayer

@onready var hp_bar = $VBoxContainer/HBoxContainer_HP/HPBar
@onready var fuel_bar = $VBoxContainer/HBoxContainer_JET/FuelBar
@onready var weapon_label = $VBoxContainer/WeaponLabel
@onready var heat_bar = $VBoxContainer/HBoxContainer/HeatBar

func update_heat(value):
	heat_bar.value = value
	heat_bar.visible = value > 0

func update_hp(value, max_value):
	hp_bar.max_value = max_value
	hp_bar.value = value

func update_fuel(value):
	fuel_bar.value = value

func update_weapon(weapon_name, mode = "", current_ammo = -1):
	var text = weapon_name.to_upper()
	if mode != "":
		text += " [" + mode.to_upper() + "]"
	if current_ammo >= 0:
		text += " | " + str(current_ammo)
	weapon_label.text = text
