class_name Player
extends CharacterBody3D
## Third-person player. WASD (camera-relative) + jump, mouse orbit camera.
## E: pick up / drop / insert piece into socket / grab rock (start push-pull) / release rock.
## While holding a rock: W pushes, S pulls (movement locked to the axis you grabbed from).
##
## Animation hooks: assign `animation_player` in the inspector. Animations used if they exist:
## idle, walk, jump, fall, carry_idle, carry_walk, push_idle, push, pull, ko

@export_group("Movement")
@export var walk_speed := 5.0
@export var carry_speed_multiplier := 0.75
@export var jump_velocity := 6.5
@export var acceleration := 12.0
@export var air_control := 4.0
@export var turn_speed := 12.0

@export_group("Push / Pull")
@export var push_speed := 1.5
@export var release_distance := 3.0   # auto-release the rock if it gets this far away

@export_group("Falling / KO")
@export var fall_limit_y := -30.0     # falling below this Y counts as falling off the map
@export var fall_damage := 20.0
@export var ko_duration := 2.5        # used when there is no "ko" animation
@export var respawn_after_ko := true

@export_group("Camera")
@export var camera_distance := 5.0
@export var pitch_min_deg := -60.0
@export var pitch_max_deg := 15.0

@export_group("Nodes")
@export var animation_player: AnimationPlayer

enum State { NORMAL, PUSHING, LOCKED }

signal picked_up(item)
signal dropped(item)

var state := State.NORMAL
var carried: Pickable = null
var respawn_point := Transform3D.IDENTITY

var _rock: PushableRock = null
var _grab_dir := Vector3.ZERO
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _yaw := 0.0
var _pitch := -0.35

@onready var model: Node3D = $Model
@onready var hold_point: Marker3D = $Model/HoldPoint
@onready var interact_area: Area3D = $Model/InteractArea
@onready var cam_pivot: Node3D = $CameraPivot
@onready var spring_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D


func _ready() -> void:
	add_to_group("player")
	collision_layer = GameData.LAYER_PLAYER
	collision_mask = GameData.LAYER_WORLD | GameData.LAYER_PICKABLE | GameData.LAYER_ROCK
	interact_area.collision_layer = 0
	interact_area.collision_mask = GameData.LAYER_PICKABLE | GameData.LAYER_ROCK | GameData.LAYER_INTERACT
	interact_area.monitorable = false

	cam_pivot.top_level = true
	cam_pivot.global_position = global_position + Vector3(0, 1.5, 0)
	spring_arm.spring_length = camera_distance
	spring_arm.add_excluded_object(get_rid())
	camera.fov = Settings.fov
	camera.make_current()

	respawn_point = global_transform
	GameState.meter_depleted.connect(_on_meter_depleted)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_yaw -= event.relative.x * Settings.mouse_sensitivity
		var dy: float = event.relative.y * Settings.mouse_sensitivity
		_pitch = clampf(_pitch + (dy if Settings.invert_y else -dy),
				deg_to_rad(pitch_min_deg), deg_to_rad(pitch_max_deg))
	elif event.is_action_pressed("interact") and state != State.LOCKED:
		_on_interact()


func _process(delta: float) -> void:
	cam_pivot.rotation.y = _yaw
	spring_arm.rotation.x = _pitch
	var target := global_position + Vector3(0, 1.5, 0)
	cam_pivot.global_position = cam_pivot.global_position.lerp(target, clampf(delta * 20.0, 0.0, 1.0))


func _physics_process(delta: float) -> void:
	if global_position.y < fall_limit_y and state != State.LOCKED:
		fall_off_map()
		return
	match state:
		State.NORMAL:
			_normal_move(delta)
		State.PUSHING:
			_push_move(delta)
		State.LOCKED:
			_locked_move(delta)
	if state != State.LOCKED:
		_update_animation()


# ------------------------------------------------------------------ MOVEMENT
func _normal_move(delta: float) -> void:
	if is_on_floor():
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_velocity
	else:
		velocity.y -= _gravity * delta

	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var dir := cam_pivot.global_basis * Vector3(input.x, 0.0, input.y)
	dir.y = 0.0
	dir = dir.normalized()

	var speed := walk_speed * (carry_speed_multiplier if carried else 1.0)
	var accel := acceleration if is_on_floor() else air_control
	var w := clampf(accel * delta, 0.0, 1.0)
	velocity.x = lerpf(velocity.x, dir.x * speed, w)
	velocity.z = lerpf(velocity.z, dir.z * speed, w)

	if dir.length() > 0.1:
		model.rotation.y = lerp_angle(model.rotation.y, atan2(-dir.x, -dir.z),
				clampf(turn_speed * delta, 0.0, 1.0))
	move_and_slide()


func _push_move(delta: float) -> void:
	if not is_instance_valid(_rock):
		stop_pushing()
		return
	var flat := _rock.global_position - global_position
	flat.y = 0.0
	if flat.length() > release_distance:
		stop_pushing()
		return

	var axis := Input.get_axis("move_back", "move_forward")  # W = +1 = push, S = -1 = pull
	var motion := _grab_dir * axis * push_speed * delta
	if axis > 0.0:
		# Push: rock moves first; the player only follows as far as the rock actually moved.
		var moved := _rock.try_move(motion)
		move_and_collide(moved)
	elif axis < 0.0:
		# Pull: player moves first; the rock follows as far as the player actually moved.
		var c := move_and_collide(motion)
		var moved := c.get_travel() if c else motion
		_rock.try_move(moved)

	velocity.x = 0.0
	velocity.z = 0.0
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= _gravity * delta
	move_and_slide()


func _locked_move(delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	if not is_on_floor():
		velocity.y -= _gravity * delta
	move_and_slide()


# ------------------------------------------------------------------ INTERACTION
func _on_interact() -> void:
	if state == State.PUSHING:
		stop_pushing()
		return
	if carried:
		var socket := _find_socket()
		if socket:
			socket.try_insert(self)
		else:
			drop_carried()
		return
	var target := _find_interactable()
	if target:
		target.interact(self)


func _find_socket() -> PuzzleSocket:
	var best: PuzzleSocket = null
	var best_d := INF
	for a in interact_area.get_overlapping_areas():
		if a is PuzzleSocket and not a.is_solved:
			var d := hold_point.global_position.distance_to(a.global_position)
			if d < best_d:
				best = a
				best_d = d
	return best


func _find_interactable() -> Node3D:
	var best: Node3D = null
	var best_d := INF
	var candidates: Array = []
	candidates.append_array(interact_area.get_overlapping_bodies())
	candidates.append_array(interact_area.get_overlapping_areas())
	for c in candidates:
		if c == self or not c.has_method("interact"):
			continue
		var d := hold_point.global_position.distance_to(c.global_position)
		if d < best_d:
			best = c
			best_d = d
	return best


func pick_up(item: Pickable) -> void:
	if carried or state != State.NORMAL or item.locked:
		return
	carried = item
	item.on_picked_up(self)
	picked_up.emit(item)


func drop_carried() -> void:
	if not carried:
		return
	var item := carried
	carried = null
	item.on_dropped(self)
	dropped.emit(item)


func start_push(rock: PushableRock) -> void:
	if carried or state != State.NORMAL or not is_on_floor():
		return
	var d := rock.global_position - global_position
	d.y = 0.0
	if absf(d.x) > absf(d.z):
		_grab_dir = Vector3(signf(d.x), 0, 0)
	else:
		_grab_dir = Vector3(0, 0, signf(d.z))
	_rock = rock
	state = State.PUSHING
	velocity = Vector3.ZERO
	model.rotation.y = atan2(-_grab_dir.x, -_grab_dir.z)


func stop_pushing() -> void:
	_rock = null
	if state == State.PUSHING:
		state = State.NORMAL


# ------------------------------------------------------------------ CONTROL LOCK (cinematics, level end)
func lock_controls() -> void:
	stop_pushing()
	state = State.LOCKED
	_play("idle")


func unlock_controls() -> void:
	state = State.NORMAL


# ------------------------------------------------------------------ FALLING / KO / RESPAWN
func fall_off_map() -> void:
	_teleport_to_respawn()
	GameState.damage(fall_damage)   # if this empties the meter, the KO sequence starts


func _teleport_to_respawn() -> void:
	stop_pushing()
	global_transform = respawn_point
	velocity = Vector3.ZERO
	cam_pivot.global_position = global_position + Vector3(0, 1.5, 0)


func _on_meter_depleted() -> void:
	if state == State.LOCKED:
		return
	stop_pushing()
	state = State.LOCKED
	_play("ko")
	var duration := ko_duration
	if animation_player and animation_player.has_animation("ko"):
		duration = animation_player.get_animation("ko").length
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.flash_ko(duration)
	await get_tree().create_timer(duration).timeout
	GameState.set_meter(GameState.MAX_METER * 0.5)
	if respawn_after_ko:
		_teleport_to_respawn()
	state = State.NORMAL


# ------------------------------------------------------------------ ANIMATION
func _update_animation() -> void:
	if animation_player == null:
		return
	var carry := "carry_" if carried else ""
	var anim_name := carry + "idle"
	if state == State.PUSHING:
		var axis := Input.get_axis("move_back", "move_forward")
		anim_name = "push_idle" if is_zero_approx(axis) else ("push" if axis > 0.0 else "pull")
	elif not is_on_floor():
		anim_name = "jump" if velocity.y > 0.0 else "fall"
	elif Vector2(velocity.x, velocity.z).length() > 0.3:
		anim_name = carry + "walk"
	_play(anim_name)


func _play(anim_name: String) -> void:
	if animation_player and animation_player.has_animation(anim_name) \
			and animation_player.current_animation != anim_name:
		animation_player.play(anim_name)
