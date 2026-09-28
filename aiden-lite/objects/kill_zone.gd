class_name KillZone
extends Area3D
## Big Area3D below/around the playable area. Player falling in: meter damage + respawn at last checkpoint.
## Boxes and rocks falling in are put back at their starting position.

func _ready() -> void:
	collision_layer = GameData.LAYER_INTERACT
	collision_mask = GameData.LAYER_PLAYER | GameData.LAYER_PICKABLE | GameData.LAYER_ROCK
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		body.call_deferred("fall_off_map")
	elif body.has_method("reset_to_start"):
		body.call_deferred("reset_to_start")
