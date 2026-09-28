class_name PuzzleSocket
extends Area3D
## Attach to an Area3D with a CollisionShape3D. The player stands next to it holding a piece and presses E.
## Right piece (matching `required_piece_id`) -> snaps in and emits `solved`.
## Wrong piece -> emits `wrong_piece` and lowers the meter by `damage_on_wrong`.

signal solved
signal wrong_piece(piece: Pickable)

@export var required_piece_id := ""
@export var damage_on_wrong := 10.0
@export var snap_point: Node3D   # optional; where the piece ends up (defaults to this node)

var is_solved := false


func _ready() -> void:
	add_to_group("socket")
	collision_layer = GameData.LAYER_INTERACT
	collision_mask = 0


func try_insert(player: Player) -> void:
	if is_solved or player.carried == null:
		return
	var piece: Pickable = player.carried
	if piece.piece_id == "" or piece.piece_id != required_piece_id:
		wrong_piece.emit(piece)
		GameState.puzzle_failed(damage_on_wrong)
		return
	player.drop_carried()
	var target := snap_point if snap_point else self
	piece.lock_at(target.global_transform)
	is_solved = true
	solved.emit()
