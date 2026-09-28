class_name LevelGoal
extends Area3D
## Area3D at the end of a level. Entering it completes the level, unlocks the next one and
## plays that level's "cinematic_after" (see GameData.LEVELS).
## Optionally assign `required_puzzle`: the goal stays inactive until that puzzle is solved.

@export var required_puzzle: PuzzleController

var _enabled := true


func _ready() -> void:
	collision_layer = GameData.LAYER_INTERACT
	collision_mask = GameData.LAYER_PLAYER
	body_entered.connect(_on_body_entered)
	if required_puzzle:
		_enabled = false
		required_puzzle.puzzle_solved.connect(enable_goal)


func enable_goal() -> void:
	_enabled = true


func _on_body_entered(body: Node3D) -> void:
	if _enabled and body is Player:
		_enabled = false
		body.lock_controls()
		GameState.complete_level.call_deferred()
