class_name PushableRock
extends CharacterBody3D
## Attach to a CharacterBody3D (CollisionShape3D child, ideally box-like).
## The Player moves it with move_and_collide, so it stops at walls, boxes, other rocks
## and never overlaps anything. It only slides along the axis the player grabbed it from.

var start_transform := Transform3D.IDENTITY
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


func _ready() -> void:
	add_to_group("pushable")
	collision_layer = GameData.LAYER_ROCK
	collision_mask = GameData.LAYER_WORLD | GameData.LAYER_PLAYER | GameData.LAYER_PICKABLE | GameData.LAYER_ROCK
	motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
	start_transform = global_transform


func _physics_process(delta: float) -> void:
	# Only gravity; horizontal movement comes exclusively from the player pushing/pulling.
	velocity.x = 0.0
	velocity.z = 0.0
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= _gravity * delta
	move_and_slide()


func interact(player: Player) -> void:
	player.start_push(self)


## Moves the rock by `motion` and returns how far it actually moved (blocked by collisions).
func try_move(motion: Vector3) -> Vector3:
	var c := move_and_collide(motion)
	return c.get_travel() if c else motion


## Used by KillZone when a rock falls off the map.
func reset_to_start() -> void:
	global_transform = start_transform
	velocity = Vector3.ZERO
