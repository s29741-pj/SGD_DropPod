extends CanvasLayer

@onready var points_label = $VBoxContainer/PointsLabel
@onready var upgrade1 = $VBoxContainer/Upgrade1
@onready var upgrade2 = $VBoxContainer/Upgrade2
@onready var upgrade3 = $VBoxContainer/Upgrade3

var available_upgrades = [
	{"id": "bolter_damage", "label": "BOLTER: +1 OBRAZENIA (200pts)"},
	{"id": "bolter_fire_rate", "label": "BOLTER: SZYBSZY RELOAD (200pts)"},
	{"id": "gatling_fire_rate", "label": "GATLING: SZYBSZY OSTRZAL (200pts)"},
	{"id": "gatling_heat", "label": "GATLING: MNIEJ PRZEGRZANIA (200pts)"},
	{"id": "max_hp", "label": "MAX HP +2 (200pts)"},
	{"id": "max_ammo", "label": "WIECEJ AMUNICJI (200pts)"}
]

var offered = []

func show_upgrades():
	get_tree().paused = true
	points_label.text = "PUNKTY: " + str(GameManager.score)
	points_label.text = "PUNKTY: " + str(GameManager.score)
	offered = available_upgrades.duplicate()
	offered.shuffle()
	offered = offered.slice(0, 3)
	upgrade1.text = offered[0]["label"]
	upgrade2.text = offered[1]["label"]
	upgrade3.text = offered[2]["label"]
	show()

func _ready():
	hide()
	upgrade1.pressed.connect(_on_upgrade1_pressed)
	upgrade2.pressed.connect(_on_upgrade2_pressed)
	upgrade3.pressed.connect(_on_upgrade3_pressed)

func apply_upgrade(index):
	if GameManager.score < GameManager.UPGRADE_COST:
		print("ZA MALO PUNKTOW")
		return
	GameManager.score -= GameManager.UPGRADE_COST
	GameManager.upgrades[offered[index]["id"]] += 1
	get_tree().paused = false
	hide()

func _on_upgrade1_pressed():
	apply_upgrade(0)

func _on_upgrade2_pressed():
	apply_upgrade(1)

func _on_upgrade3_pressed():
	apply_upgrade(2)
