extends Area2D

@onready var sfx_player = $SFXPlayer
@export var sfx_checkpoint: AudioStream
var activated = false

func _ready():
	#var err = body_entered.connect(_on_body_entered)
	#print("CHECKPOINT PODPIECIE: ", err)
	$Sprite.play("idle")
	body_entered.connect(_on_body_entered)
	$Sprite.play("idle")
	#print("CHECKPOINT GOTOWY, maska: ", collision_mask)

func _on_body_entered(body):
	#print("CHECKPOINT WYKRYL: ", body.name)
	if body.is_in_group("player") and not activated:
		activated = true
		$Sprite.play("checked")
		if sfx_checkpoint:
			sfx_player.stream = sfx_checkpoint
			sfx_player.play()
		GameManager.save_checkpoint(
			body.global_position,
			get_tree().current_scene.scene_file_path
		)
		GameManager.checkpoint_data["hp"] = body.hp
		GameManager.checkpoint_data["ammo_bolter"] = body.ammo["bolter"]
		GameManager.checkpoint_data["ammo_gatling"] = body.ammo.get("gatling", 0)
		GameManager.checkpoint_data["has_gatling"] = body.has_gatling
		GameManager._write_save()
		#print("CHECKPOINT ZAPISANY")
