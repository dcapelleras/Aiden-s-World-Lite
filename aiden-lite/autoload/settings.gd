extends Node
## AUTOLOAD "Settings"
## Owns the input map (so you don't have to set it up in the editor), user options,
## audio buses (Master / Music / SFX) and saving to user://settings.cfg

const PATH := "user://settings.cfg"

const ACTION_LABELS := {
	"move_forward": "Move forward / Push",
	"move_back": "Move back / Pull",
	"move_left": "Move left",
	"move_right": "Move right",
	"jump": "Jump",
	"interact": "Interact / Grab / Drop",
	"journal": "Journal",
}

const DEFAULT_KEYS := {
	"move_forward": KEY_W,
	"move_back": KEY_S,
	"move_left": KEY_A,
	"move_right": KEY_D,
	"jump": KEY_SPACE,
	"interact": KEY_E,
	"journal": KEY_J,
}

var master_volume := 1.0
var music_volume := 0.8
var sfx_volume := 1.0
var fullscreen := false
var vsync := true
var fov := 75.0
var mouse_sensitivity := 0.003
var invert_y := false
var keys := {}  # action -> physical keycode


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	keys = DEFAULT_KEYS.duplicate()
	_ensure_buses()
	load_settings()
	_apply_keys()
	apply()


func _ensure_buses() -> void:
	for bus_name in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			var idx := AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, "Master")


func _apply_keys() -> void:
	for action in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		InputMap.action_erase_events(action)
		var ev := InputEventKey.new()
		ev.physical_keycode = int(keys[action])
		InputMap.action_add_event(action, ev)


func set_key(action: String, physical_keycode: int) -> void:
	keys[action] = physical_keycode
	_apply_keys()


func key_text(action: String) -> String:
	var code := DisplayServer.keyboard_get_keycode_from_physical(int(keys[action]))
	return OS.get_keycode_string(code)


func reset_keys() -> void:
	keys = DEFAULT_KEYS.duplicate()
	_apply_keys()


func apply() -> void:
	_set_bus("Master", master_volume)
	_set_bus("Music", music_volume)
	_set_bus("SFX", sfx_volume)
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)


func _set_bus(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	AudioServer.set_bus_mute(idx, linear <= 0.001)
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(linear, 0.001)))


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master", master_volume)
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.set_value("video", "fullscreen", fullscreen)
	cfg.set_value("video", "vsync", vsync)
	cfg.set_value("video", "fov", fov)
	cfg.set_value("controls", "sensitivity", mouse_sensitivity)
	cfg.set_value("controls", "invert_y", invert_y)
	for action in keys:
		cfg.set_value("keys", action, int(keys[action]))
	cfg.save(PATH)


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	master_volume = cfg.get_value("audio", "master", master_volume)
	music_volume = cfg.get_value("audio", "music", music_volume)
	sfx_volume = cfg.get_value("audio", "sfx", sfx_volume)
	fullscreen = cfg.get_value("video", "fullscreen", fullscreen)
	vsync = cfg.get_value("video", "vsync", vsync)
	fov = cfg.get_value("video", "fov", fov)
	mouse_sensitivity = cfg.get_value("controls", "sensitivity", mouse_sensitivity)
	invert_y = cfg.get_value("controls", "invert_y", invert_y)
	for action in keys:
		keys[action] = int(cfg.get_value("keys", action, keys[action]))
