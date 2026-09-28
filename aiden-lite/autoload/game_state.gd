extends Node
## AUTOLOAD "GameState"
## Meter, level progression, collectibles, save/load and scene transitions (with fade).

signal meter_changed(value: float, max_value: float)
signal meter_depleted
signal collectible_unlocked(id: String)
signal progress_changed

const SAVE_PATH := "user://save.json"
const MAX_METER := 100.0

var meter := MAX_METER
var unlocked_levels := 1          # how many levels are unlocked (1 = only the first)
var collected: Array[String] = []
var current_level := 0            # index in GameData.LEVELS

var _after_cinematic := "map"     # "map" or "credits"
var _fade: ColorRect
var _changing := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_fade()
	load_game()


# ---------------------------------------------------------------- METER
func damage(amount: float) -> void:
	if meter <= 0.0:
		return
	set_meter(meter - amount)
	if meter <= 0.0:
		meter_depleted.emit()


func heal(amount: float) -> void:
	set_meter(minf(meter + amount, MAX_METER))


func set_meter(value: float) -> void:
	meter = clampf(value, 0.0, MAX_METER)
	meter_changed.emit(meter, MAX_METER)


## Call this from any custom puzzle when the player gets it wrong.
func puzzle_failed(amount: float = 10.0) -> void:
	damage(amount)


# ---------------------------------------------------------------- COLLECTIBLES
func is_collected(id: String) -> bool:
	return id in collected


func collect(id: String) -> void:
	if is_collected(id):
		return
	collected.append(id)
	save_game()
	collectible_unlocked.emit(id)


# ---------------------------------------------------------------- FLOW
func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func new_game() -> void:
	collected.clear()
	unlocked_levels = 1
	current_level = 0
	save_game()
	progress_changed.emit()
	play_cinematic(GameData.INTRO_CINEMATIC, "map")


func continue_game() -> void:
	change_scene(GameData.MAP_SCENE)


func start_level(index: int) -> void:
	if index < 0 or index >= unlocked_levels or index >= GameData.LEVELS.size():
		return
	current_level = index
	change_scene(GameData.LEVELS[index]["scene"])


## Call when the player reaches the end of a level (LevelGoal does this).
func complete_level() -> void:
	var i := current_level
	unlocked_levels = maxi(unlocked_levels, mini(i + 2, GameData.LEVELS.size()))
	save_game()
	progress_changed.emit()
	var is_last: bool = i >= GameData.LEVELS.size() - 1
	var next_step := "credits" if is_last else "map"
	var cinematic: String = GameData.LEVELS[i].get("cinematic_after", "")
	if cinematic != "":
		play_cinematic(cinematic, next_step)
	else:
		_after_cinematic = next_step
		cinematic_finished()


func play_cinematic(path: String, next_step: String) -> void:
	_after_cinematic = next_step
	change_scene(path)


## Cinematic scenes call this when they end.
func cinematic_finished() -> void:
	if _after_cinematic == "credits":
		change_scene(GameData.CREDITS_SCENE)
	else:
		change_scene(GameData.MAP_SCENE)


# ---------------------------------------------------------------- SCENE CHANGE
func change_scene(path: String, fade_time: float = 0.5) -> void:
	if _changing:
		return
	_changing = true
	var t := create_tween()
	t.tween_property(_fade, "color:a", 1.0, fade_time)
	await t.finished
	get_tree().paused = false
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	t = create_tween()
	t.tween_property(_fade, "color:a", 0.0, fade_time)
	await t.finished
	_changing = false


func _build_fade() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_fade)
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


# ---------------------------------------------------------------- SAVE / LOAD
func save_game() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"unlocked_levels": unlocked_levels, "collected": collected}))


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if data is Dictionary:
		unlocked_levels = int(data.get("unlocked_levels", 1))
		collected.clear()
		for c in data.get("collected", []):
			collected.append(str(c))
