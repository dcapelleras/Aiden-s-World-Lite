class_name LevelBase
extends Node3D
## Attach to the root Node3D of every level scene. Adds the HUD, captures the mouse,
## refills the meter and (optionally) plays level music. The level must contain an instance of player.tscn.

@export var level_music: AudioStream


func _ready() -> void:
	add_child(Hud.new())
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	Journal.enabled = true
	GameState.set_meter(GameState.MAX_METER)
	if level_music:
		var p := AudioStreamPlayer.new()
		p.stream = level_music
		p.bus = "Music"
		add_child(p)
		p.play()
