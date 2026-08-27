extends Area3D

@export var respawnPosition : Vector3 

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group('player'):
		body.position = respawnPosition
		body._reduce_calmness()
