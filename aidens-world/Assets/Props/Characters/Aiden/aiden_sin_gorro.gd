extends Node3D

var moveSpeed : float = 100

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	

func _physics_process(delta: float) -> void:
	var velocityForward = 0
	var velocityRight = 0
	if Input.is_action_pressed("ui_left"):
		velocityRight = -1
	if Input.is_action_pressed("ui_right"):
		velocityRight = 1
	if Input.is_action_pressed("ui_up"):
		velocityForward = 1
	if Input.is_action_pressed("ui_down"):
		velocityForward = -1
	var totalVelocity = Vector3.ZERO
	totalVelocity = (velocityForward, 0, velocityRight) * moveSpeed
	position += totalVelocity * delta
