extends Node3D

@onready var statues: Array[Node]

		
func _ready() -> void:
	statues = get_tree().get_nodes_in_group("Statues")


func _check_puzzle():
	for piece in statues:
		
