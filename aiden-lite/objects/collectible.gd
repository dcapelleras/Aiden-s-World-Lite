class_name Collectible
extends Area3D
## Area3D + CollisionShape3D + your visual model as children.
## Set `collectible_id` to an id from GameData.COLLECTIBLES. Walking into it unlocks the
## journal entry and opens the journal on it. Already-collected items don't spawn again.

@export var collectible_id := ""
@export var spin_speed := 1.5


func _ready() -> void:
	collision_layer = GameData.LAYER_INTERACT
	collision_mask = GameData.LAYER_PLAYER
	if GameState.is_collected(collectible_id):
		queue_free()
		return
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	rotate_y(spin_speed * delta)


func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		GameState.collect.call_deferred(collectible_id)
		queue_free()
