extends Area2D

var activated = false

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player") and not activated:
		activated = true
		$ColorRect.color = Color(0.0, 1.0, 0.0)
		GameManager.save_checkpoint(
			body.global_position,
			get_tree().current_scene.scene_file_path
		)
		GameManager.checkpoint_data["hp"] = body.hp
		GameManager.checkpoint_data["ammo_bolter"] = body.ammo["bolter"]
		GameManager.checkpoint_data["ammo_gatling"] = body.ammo["gatling"]
		GameManager._write_save()
		print("CHECKPOINT ZAPISANY")
