extends Control

@onready var menuSettings: Control = $"../MenuSettings"
@onready var menuCredits: Control = $"../MenuCredits"

func _on_Start_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Level_Hub.tscn")


func _on_Settings_down() -> void:
	menuSettings.visible = true
	await get_tree().create_timer(2.0).timeout
	menuSettings.visible = false
	
func _on_Credits_pressed() -> void:
	menuCredits.visible = true
	await get_tree().create_timer(2.0).timeout
	menuCredits.visible = false


func _on_Quit_pressed() -> void:
	get_tree().quit()
