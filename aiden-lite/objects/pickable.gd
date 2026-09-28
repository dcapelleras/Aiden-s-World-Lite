class_name Pickable
extends RigidBody3D
## Attach to a RigidBody3D (with a CollisionShape3D child, origin at the object's center).
## - Leave `piece_id` empty for a plain box; set it (e.g. "red_gear") for a puzzle piece.
## - Boxes stack: dropping one above another snaps it neatly on top (and centers it).

@export var piece_id := ""
@export var stackable := true
@export var fallback_half_height := 0.5   # used if the collision shape isn't a box/sphere/capsule/cylinder

var locked := false            # true once inserted in a socket
var holder: Player = null
var start_transform := Transform3D.IDENTITY

var _orig_parent: Node


func _ready() -> void:
	add_to_group("pickable")
	collision_layer = GameData.LAYER_PICKABLE
	collision_mask = GameData.LAYER_WORLD | GameData.LAYER_PLAYER | GameData.LAYER_PICKABLE | GameData.LAYER_ROCK
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	start_transform = global_transform
	_orig_parent = get_parent()


func interact(player: Player) -> void:
	player.pick_up(self)


func on_picked_up(player: Player) -> void:
	holder = player
	_orig_parent = get_parent() if get_parent() != player.hold_point else _orig_parent
	freeze = true
	add_collision_exception_with(player)
	player.add_collision_exception_with(self)
	reparent(player.hold_point, false)
	position = Vector3.ZERO
	rotation = Vector3.ZERO


func on_dropped(player: Player) -> void:
	var xf := _compute_drop_transform(player)
	reparent(_orig_parent, false)
	global_transform = xf
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	freeze = false
	holder = null
	# Keep ignoring the player briefly so the box doesn't get shoved into them.
	await get_tree().create_timer(0.4).timeout
	if is_instance_valid(player):
		remove_collision_exception_with(player)
		player.remove_collision_exception_with(self)


## Called by a PuzzleSocket after a correct insertion.
func lock_at(t: Transform3D) -> void:
	locked = true
	freeze = true
	global_transform = t


## Used by KillZone when a box falls off the map.
func reset_to_start() -> void:
	if locked:
		return
	if holder:
		holder.carried = null
		holder = null
		reparent(_orig_parent, false)
	freeze = false
	global_transform = start_transform
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO


func get_half_height() -> float:
	for c in get_children():
		if c is CollisionShape3D and c.shape:
			var s = c.shape
			var k := global_transform.basis.get_scale().y
			if s is BoxShape3D:
				return s.size.y * 0.5 * k
			if s is SphereShape3D:
				return s.radius * k
			if s is CapsuleShape3D or s is CylinderShape3D:
				return s.height * 0.5 * k
	return fallback_half_height


func get_top_y() -> float:
	return global_position.y + get_half_height()


func _compute_drop_transform(player: Player) -> Transform3D:
	var origin := player.hold_point.global_position
	var facing := Basis(Vector3.UP, player.model.rotation.y)
	var xf := Transform3D(facing, origin)

	var space := get_world_3d().direct_space_state
	var mask := GameData.LAYER_WORLD | GameData.LAYER_PICKABLE | GameData.LAYER_ROCK
	var q := PhysicsRayQueryParameters3D.create(
			origin + Vector3.UP * 0.5, origin + Vector3.DOWN * 4.0, mask, [get_rid(), player.get_rid()])
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		return xf

	var half := get_half_height()
	var below = hit["collider"]
	if below is Pickable and below.stackable:
		# Stack: center on the lower box, aligned with its rotation, resting on its top.
		var pos: Vector3 = below.global_position
		pos.y = below.get_top_y() + half + 0.01
		return Transform3D(Basis(Vector3.UP, below.global_rotation.y), pos)

	var ground: Vector3 = hit["position"]
	ground.y += half + 0.02
	return Transform3D(facing, ground)
