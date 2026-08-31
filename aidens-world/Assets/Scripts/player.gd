extends CharacterBody3D

@export var speed: float = 5.0
@export var acceleration: float = 15.0 # Smooths out movement start/stop
@export var rotation_speed: float = 10.0 # How fast the character turns
@export var mouse_sensitivity: float = 0.003
var calmness: float = 100
@export var initialCalmness: float = 50
@export var calmPenalty: float = 30

@export var jump_velocity: float = 4.5 # Initial upward force
var wants_to_jump: bool = false       # Input flag
var has_object: bool = false
var held_object: Node3D = null

# Node References
# Match these node names EXACTLY to your Scene Tree!
@onready var camera_pivot: Node3D = $CameraPivot
@onready var spring_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var visuals: Node3D = $Node3D/Aiden # Renamed to match your description
@onready var pickupPos : Node3D = $Node3D/Aiden/Armature/Skeleton3D/BoneAttachment3D/pickPos
@onready var pickArea : Area3D = $Area3D
@onready var level_node = get_tree().current_scene

# Animation references
@onready var anim_tree: AnimationTree = $Node3D/Aiden/AnimationTree
@onready var anim_state = anim_tree.get("parameters/playback")

# Get default project gravity
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# Prevents camera from clipping into player's collision shape
	spring_arm.add_excluded_object(get_rid())
	calmness = initialCalmness

func _unhandled_input(event: InputEvent) -> void:
	# Mouse Look Logic
	if event is InputEventMouseMotion:
		camera_pivot.rotate_y(-event.relative.x * mouse_sensitivity)
		spring_arm.rotate_x(-event.relative.y * mouse_sensitivity)
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, deg_to_rad(-60), deg_to_rad(30))
		
	# Jump Input Catch
	if event.is_action_pressed("ui_jump"):
		wants_to_jump = true
		
	if event.is_action_pressed("ui_interact"):
		_try_pickup()



func _physics_process(delta: float) -> void:
	
	# 1. Gravity Management
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		# Tiny downward force keeps is_on_floor() stable without clipping
		velocity.y = -0.1 

	# 2. Jump Handling (Calculated before movement)
	if wants_to_jump:
		if is_on_floor():
			velocity.y = jump_velocity
		# Reset flag immediately so we don't jump again automatically upon landing
		wants_to_jump = false
		anim_state.travel("Jump")

	# 3. WASD Movement Logic
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# Calculate movement direction relative to camera rotation
	var basis := camera_pivot.global_transform.basis
	var direction := (basis.z * input_dir.y + basis.x * input_dir.x).normalized()
	direction.y = 0 # Keep movement purely horizontal

	# 4. Movement Acceleration & Visual Rotation
	if direction != Vector3.ZERO:
		velocity.x = move_toward(velocity.x, direction.x * speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, direction.z * speed, acceleration * delta)
		
		# Rotate character visual mesh to face movement direction
		var target_angle = atan2(-direction.x, -direction.z)
		visuals.rotation.y = lerp_angle(visuals.rotation.y, target_angle, rotation_speed * delta)
	else:
		# Smooth deceleration to zero
		velocity.x = move_toward(velocity.x, 0, acceleration * delta)
		velocity.z = move_toward(velocity.z, 0, acceleration * delta)

	# 5. Animation State Control (Grounded vs Air logic)

	# 6. Execute Physics Move
	move_and_slide()

	_update_animations(direction)



# Clean helper function to keep _physics_process tidy
func _update_animations(direction: Vector3) -> void:
	if not anim_state:#
		return
		
	if is_on_floor():
		if direction != Vector3.ZERO:
			anim_state.travel("Run")
		else:
			anim_state.travel("Idle")
	else:
		# Only switch to falling if we are actually moving downward in the air
		if not is_on_floor() and velocity.y < -0.1:
			anim_state.travel("Fall")
			
func _try_pickup() -> void:
	print("trypickup")
	if has_object:
		var puzzle = _get_nearby_puzzle()
		if puzzle:
			_interact_with_puzzle(puzzle)
		elif _can_drop():
			_drop_object()
		else:
			print("Can't drop here — something's in the way")
	else:
		_pick_object()

func _get_nearby_puzzle() -> Node:
	# Check both bodies and areas, in case your puzzle uses either
	for body in pickArea.get_overlapping_bodies():
		if body.is_in_group("Puzzle"):
			return body
	for area in pickArea.get_overlapping_areas():
		if area.is_in_group("Puzzle"):
			return area
	return null
	
func _interact_with_puzzle(puzzle: Node) -> void:
	print("interacting with puzzle: ", puzzle.name)
	if puzzle.has_method("solve"):
		puzzle.solve(held_object)

func _can_drop() -> bool:
	var space_state := get_world_3d().direct_space_state
	var from := global_position + Vector3.UP * 1.0
	var to := from + (-global_transform.basis.z) * 1.5 # 1.5m in front of player
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [self, held_object]
	var result := space_state.intersect_ray(query)
	return result.is_empty()
	
func _drop_object() -> void:
	print("drop")
	held_object.global_rotation = self.global_rotation
	held_object.reparent(level_node)
	has_object = false
	held_object = null
	_increase_calmness()
	pass
	
func _pick_object() -> void:
	var bodies = pickArea.get_overlapping_bodies()
	var closest_body: RigidBody3D = null
	var min_distance: float = INF
	_reduce_calmness()
	
	# Find the closest pickable object in range
	for body in bodies:
		if body.is_in_group("Pickable"):
			var dist = global_position.distance_to(body.global_position)
			if dist < min_distance:
				min_distance = dist
				closest_body = body
				
	if closest_body != null:
		held_object = closest_body
		held_object.gravity_scale = 0.0
		held_object.linear_damp = 10.0
		has_object = true
		var shape = held_object.get_node("CollisionShape3D")
		shape.set_deferred("disabled", false)
		held_object.reparent(pickupPos)
		held_object.transform = Transform3D.IDENTITY
		print(held_object)
		
func _reduce_calmness() -> void:
	var tween: Tween = create_tween()
	var clampedValue = clampf(calmness - calmPenalty, 0, 100)
	tween.tween_method(_on_variable_interpolated, calmness, clampedValue, 2.0)
	tween.set_trans(Tween.TRANS_SINE)
	if calmness <= 0:
		tween.kill()
		_death()
	tween.set_ease(Tween.EASE_OUT)
		
func _increase_calmness() -> void:
	var tween: Tween = create_tween()
	tween.tween_method(_on_variable_interpolated, calmness, 100.0, 2.0)
	tween.set_trans(Tween.TRANS_SINE)
	if calmness >= 100:
		calmness = 100
		tween.kill()
	tween.set_ease(Tween.EASE_OUT)
	

func _on_variable_interpolated(current_value: float) -> void:
	calmness = current_value
	print("Variable updated to: ", calmness)
		
func _death() -> void:
	print("death")
	calmness = 0
	await get_tree().create_timer(3.0).timeout
	print("revived")
	calmness = 50
