extends Node3D

var statues: int = 0
@export var statuesToSolve: int = 6
var solved: bool = false

func _check_puzzle(solved):
	statues ++ 1
	if statues == statuesToSolve:
		solved = true
