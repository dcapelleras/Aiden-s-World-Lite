extends RigidBody3D

@export var object_type: String = "Box"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
	
func _object_action() -> void:
	if object_type == "Box":
		print("action of the box")
	if object_type == "Mask":
		print("action of the mask")
	pass
