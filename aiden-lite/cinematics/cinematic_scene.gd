class_name CinematicScene
extends Node3D
## Root script for cinematic scenes (cinematics/cinematic_1.tscn, _2, _3 ...).
## Root node must be a Node3D. Build the cutscene however you like (Camera3D, models, subtitles UI...)
## and drive it with an AnimationPlayer (use Call Method tracks for dialogue, sounds, etc.)
## or a VideoStreamPlayer. When it ends, the game continues to the map (or the credits after the last one).
## Press Esc to skip when `allow_skip` is on.

@export var animation_player: AnimationPlayer
@export var animation_name := ""              # empty = first animation found
@export var video_player: VideoStreamPlayer   # optional, for pre-rendered video
@export var music: AudioStream
@export var allow_skip := true

var _done := false


func _ready() -> void:
	Journal.enabled = false
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	get_tree().paused = false

	if music:
		var p := AudioStreamPlayer.new()
		p.stream = music
		p.bus = "Music"
		add_child(p)
		p.play()

	var started := false
	if video_player:
		video_player.finished.connect(_finish)
		video_player.play()
		started = true
	if animation_player:
		var n := animation_name
		if n == "":
			for a in animation_player.get_animation_list():
				if a != "RESET":
					n = a
					break
		if n != "" and animation_player.has_animation(n):
			animation_player.animation_finished.connect(_on_anim_finished)
			animation_player.play(n)
			started = true
	if not started:
		push_warning("CinematicScene: nothing to play, skipping.")
		await get_tree().create_timer(1.0).timeout
		_finish()


func _on_anim_finished(_n: StringName) -> void:
	_finish()


func _unhandled_input(event: InputEvent) -> void:
	if allow_skip and event.is_action_pressed("ui_cancel"):
		_finish()


func _finish() -> void:
	if _done:
		return
	_done = true
	Journal.enabled = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	GameState.cinematic_finished()
