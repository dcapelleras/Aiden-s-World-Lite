extends CharacterBody3D

@export var speed: float = 5.0
@export var acceleration: float = 15.0 # Smooths out movement start/stop
@export var rotation_speed: float = 10.0 # How fast the character turns
@export var mouse_sensitivity: float = 0.003

@export var jump_velocity: float = 4.5 # Initial upward force
var wants_to_jump: bool = false       # Input flag
var has_object: bool = false

# Node References
# Match these node names EXACTLY to your Scene Tree!
@onready var camera_pivot: Node3D = $CameraPivot
@onready var spring_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var visuals: Node3D = $Node3D/Aiden # Renamed to match your description

# Animation references
@onready var anim_tree: AnimationTree = $Node3D/Aiden/AnimationTree
@onready var anim_state = anim_tree.get("parameters/playback")

# Get default project gravity
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# Prevents camera from clipping into player's collision shape
	spring_arm.add_excluded_object(get_rid())

func _unhandled_input(event: InputEvent) -> void:
	# Mouse Look Logic
	if event is InputEventMouseMotion:
		camera_pivot.rotate_y(-event.relative.x * mouse_sensitivity)
		spring_arm.rotate_x(-event.relative.y * mouse_sensitivity)
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, deg_to_rad(-60), deg_to_rad(30))
		
	# Jump Input Catch
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_jump"):
		wants_to_jump = true
		
	if event.is_action_pressed("ui_interact") and !has_object:
		has_object = true



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
			if anim_state:
				anim_state.travel("Jump")
		# Reset flag immediately so we don't jump again automatically upon landing
		wants_to_jump = false

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
	_update_animations(direction)

	# 6. Execute Physics Move
	move_and_slide()

# Clean helper function to keep _physics_process tidy
func _update_animations(direction: Vector3) -> void:
	if not anim_state:
		return
		
	if is_on_floor():
		if direction != Vector3.ZERO:
			anim_state.travel("Run")
		else:
			anim_state.travel("Idle")
	#else:
		# Only switch to falling if we are actually moving downward in the air
		#if velocity.y < 0:
			#anim_state.travel("Falling")
