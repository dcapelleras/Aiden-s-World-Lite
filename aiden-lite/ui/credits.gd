extends Control
## Auto-scrolling credits from GameData.CREDITS. Any key / Esc / click skips. Returns to the main menu.

@export var scroll_speed := 60.0   # pixels per second
@export var music: AudioStream

var _tween: Tween
var _done := false


func _ready() -> void:
	Journal.enabled = false
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	var screen := get_viewport_rect().size

	var bg := ColorRect.new()
	bg.color = Color.BLACK
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 18)
	vb.custom_minimum_size = Vector2(screen.x, 0)
	for line in GameData.CREDITS:
		var l := Label.new()
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if line.begins_with("# "):
			l.text = line.substr(2)
			l.add_theme_font_size_override("font_size", 40)
		else:
			l.text = line
			l.add_theme_font_size_override("font_size", 24)
		vb.add_child(l)
	add_child(vb)
	vb.position = Vector2(0, screen.y)

	if music:
		var p := AudioStreamPlayer.new()
		p.stream = music
		p.bus = "Music"
		add_child(p)
		p.play()

	await get_tree().process_frame
	var distance := screen.y + vb.size.y
	_tween = create_tween()
	_tween.tween_property(vb, "position:y", -vb.size.y, distance / scroll_speed)
	await _tween.finished
	_exit()


func _unhandled_input(event: InputEvent) -> void:
	if (event is InputEventKey or event is InputEventMouseButton) and event.pressed:
		_exit()


func _exit() -> void:
	if _done:
		return
	_done = true
	if _tween:
		_tween.kill()
	GameState.change_scene(GameData.MENU_SCENE)
