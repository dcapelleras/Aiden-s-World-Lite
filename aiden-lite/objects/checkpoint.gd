class_name Checkpoint
extends Area3D
## Area3D placed on the floor. Touching it sets where the player respawns
## after falling off the map or being knocked out.

func _ready() -> void:
	collision_layer = GameData.LAYER_INTERACT
	collision_mask = GameData.LAYER_PLAYER
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		body.respawn_point = Transform3D(Basis.IDENTITY, global_position + Vector3.UP * 0.2)
