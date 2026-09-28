class_name PuzzleController
extends Node
## Add as a plain Node in your level. Drag your PuzzleSockets into `sockets`.
## When all are solved it emits `puzzle_solved` and (optionally) plays an animation (open a door, etc.).
## For custom puzzles (levers, sequences...) call GameState.puzzle_failed() on a mistake.

signal puzzle_solved

@export var sockets: Array[PuzzleSocket] = []
@export var animation_player: AnimationPlayer
@export var animation_name := ""

var is_done := false


func _ready() -> void:
	for s in sockets:
		s.solved.connect(_check)


func _check() -> void:
	if is_done:
		return
	for s in sockets:
		if not s.is_solved:
			return
	is_done = true
	puzzle_solved.emit()
	if animation_player and animation_name != "":
		animation_player.play(animation_name)
