class_name CinematicSpot
extends Area3D
## Area3D marking the spot. When the player enters (or presses E if `require_interact`),
## controls lock, `animation_name` plays on `animation_player` (animate a Camera3D, characters, etc.),
## and the meter regenerates slowly by `heal_amount` over the length of the animation.

signal cinematic_started
signal cinematic_finished

@export var animation_player: AnimationPlayer
@export var animation_name := "cinematic"
@export var cinematic_camera: Camera3D       # optional: made current during the cinematic
@export var heal_amount := 100.0             # total meter regained over the whole cinematic
@export var fallback_duration := 5.0         # used if there is no animation
@export var require_interact := false
@export var play_once := false

var _playing := false
var _played := false
var _last_heal := 0.0


func _ready() -> void:
	collision_layer = GameData.LAYER_INTERACT
	collision_mask = GameData.LAYER_PLAYER
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if body is Player and not require_interact:
		_start(body)


func interact(player: Player) -> void:
	if require_interact:
		_start(player)


func _start(player: Player) -> void:
	if _playing or (play_once and _played):
		return
	_playing = true
	_played = true
	player.lock_controls()
	Journal.enabled = false
	if cinematic_camera:
		cinematic_camera.make_current()
	cinematic_started.emit()

	var duration := fallback_duration
	if animation_player and animation_player.has_animation(animation_name):
		duration = animation_player.get_animation(animation_name).length
		animation_player.play(animation_name)
	duration = maxf(duration, 0.1)

	_last_heal = 0.0
	var tw := create_tween()
	tw.tween_method(_heal_step, 0.0, heal_amount, duration)
	await tw.finished

	player.camera.make_current()
	player.unlock_controls()
	Journal.enabled = true
	_playing = false
	cinematic_finished.emit()


func _heal_step(total: float) -> void:
	GameState.heal(total - _last_heal)
	_last_heal = total
