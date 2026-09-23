extends Node3D

var _solved: bool = false
@export var solver : Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("Statues")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _solve() -> void:
	_solved = true
	solver._check_puzzle.emit(_solved)
	pass
