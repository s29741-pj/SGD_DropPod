extends CanvasLayer

#@onready var hp_bar = $VBoxContainer/HBoxContainer_HP/HPBar
#@onready var fuel_bar = $VBoxContainer/HBoxContainer_JET/FuelBar
#@onready var weapon_label = $VBoxContainer/WeaponLabel
#@onready var heat_bar = $VBoxContainer/HBoxContainer/HeatBar
#@onready var score_label = $VBoxContainer/ScoreLabel
#@onready var upgrades_panel = $VBoxContainer/UpgradesPanel
#@onready var bolter_dmg_label = $VBoxContainer/UpgradesPanel/BolterDmgLabel
#@onready var bolter_rate_label = $VBoxContainer/UpgradesPanel/BolterRateLabel
#@onready var gatling_rate_label = $VBoxContainer/UpgradesPanel/GatlingRateLabel
#@onready var gatling_heat_label = $VBoxContainer/UpgradesPanel/GatlingHeatLabel
#@onready var max_hp_label = $VBoxContainer/UpgradesPanel/MaxHPLabel
#@onready var max_ammo_label = $VBoxContainer/UpgradesPanel/MaxAmmoLabel

@onready var hp_bar = $VBoxContainer/HBoxContainer_HP/HPBar
@onready var fuel_bar = $VBoxContainer/HBoxContainer_JET/FuelBar
@onready var weapon_label = $VBoxContainer/WeaponLabel
@onready var heat_bar = $VBoxContainer/HBoxContainer/HeatBar
@onready var score_label = $VBoxContainer/ScoreLabel
@onready var upgrades_panel = $UpgradesPanel
@onready var bolter_dmg_label = $UpgradesPanel/BolterDmgLabel
@onready var bolter_rate_label = $UpgradesPanel/BolterRateLabel
@onready var gatling_rate_label = $UpgradesPanel/GatlingRateLabel
@onready var gatling_heat_label = $UpgradesPanel/GatlingHeatLabel
@onready var max_hp_label = $UpgradesPanel/MaxHPLabel
@onready var max_ammo_label = $UpgradesPanel/MaxAmmoLabel


func update_upgrades():
	var u = GameManager.upgrades
	bolter_dmg_label.text = "DMG: " + "+".repeat(u["bolter_damage"]) if u["bolter_damage"] > 0 else ""
	bolter_rate_label.text = "RATE: " + "+".repeat(u["bolter_fire_rate"]) if u["bolter_fire_rate"] > 0 else ""
	gatling_rate_label.text = "G.RATE: " + "+".repeat(u["gatling_fire_rate"]) if u["gatling_fire_rate"] > 0 else ""
	gatling_heat_label.text = "HEAT: " + "+".repeat(u["gatling_heat"]) if u["gatling_heat"] > 0 else ""
	max_hp_label.text = "HP: " + "+".repeat(u["max_hp"]) if u["max_hp"] > 0 else ""
	max_ammo_label.text = "AMMO: " + "+".repeat(u["max_ammo"]) if u["max_ammo"] > 0 else ""
	upgrades_panel.visible = u.values().any(func(v): return v > 0)

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

func update_score(value):
	score_label.text = "SCORE: " + str(value)
