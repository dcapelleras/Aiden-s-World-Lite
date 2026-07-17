extends CharacterBody3D

@export var speed: float = 5.0
@export var acceleration: float = 15.0 # Smooths out movement start/stop
@export var rotation_speed: float = 10.0 # How fast the character turns
@export var mouse_sensitivity: float = 0.003

@export var jump_velocity: float = 4.5 # Initial upward force
var wants_to_jump: bool = false       # Input flag

# Node References
@onready var camera_pivot: Node3D = $CameraPivot
@onready var spring_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var visuals: Node3D = $visuals/Aiden_SinGorro

# Get the gravity from the project settings so we aren't hardcoding it
# (Unity: Physics.gravity.y)
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# Tell the SpringArm3D to ignore colliding with the player itself
	spring_arm.add_excluded_object(get_rid())

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		# Rotate the pivot horizontally (Left/Right)
		camera_pivot.rotate_y(-event.relative.x * mouse_sensitivity)
		# Rotate the spring arm vertically (Up/Down)
		spring_arm.rotate_x(-event.relative.y * mouse_sensitivity)
		# Clamp the camera boom angle so it doesn't flip upside down
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, deg_to_rad(-60), deg_to_rad(30))
		
	if event.is_action_pressed("ui_jump"):
		wants_to_jump = true


func _physics_process(delta: float) -> void:
	# 1. Clean Gravity Handling
	# If we are on the floor, we apply a tiny downward force to keep is_on_floor() stable,
	# but we NEVER accumulate gravity. This stops the character from clipping into the floor.
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = -0.1 

	if wants_to_jump:# and is_on_floor():
		# Always reset the input flag in the physics step so it doesn't float around
		wants_to_jump = false
		velocity.y = jump_velocity
	
	# 2. Get WASD Input Direction
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# Calculate move direction relative to the Camera Pivot's Y rotation
	var basis := camera_pivot.global_transform.basis
	var direction := (basis.z * input_dir.y + basis.x * input_dir.x).normalized()
	direction.y = 0 # Lock movement to the horizontal plane

	# 3. Apply Smooth Movement (Acceleration/Friction)
	if direction != Vector3.ZERO:
		# Lerp horizontal velocity towards our target
		velocity.x = move_toward(velocity.x, direction.x * speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, direction.z * speed, acceleration * delta)
		
		# 4. Rotate Player Visuals to face movement direction (Unity: Quaternion.LookRotation/Slerp)
		# We interpolate (lerp_angle) the Y rotation to keep turning silky smooth.
		var target_angle = atan2(-direction.x, -direction.z)
		visuals.rotation.y = lerp_angle(visuals.rotation.y, target_angle, rotation_speed * delta)
	else:
		
		velocity.x = 0
		velocity.z = 0

	# 5. Move execution
	move_and_slide()
