extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.



func _on_Start_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Level_Hub.tscn")


func _on_Settings_down() -> void:
	pass # Replace with function body.


func _on_Credits_pressed() -> void:
	pass # Replace with function body.


func _on_Quit_pressed() -> void:
	pass # Replace with function body.
