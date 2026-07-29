extends Area3D

@export var checkPos : Vector3
@export var abismo : Area3D


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group('player'):
		abismo.respawnPosition = checkPos
		print(checkPos)
