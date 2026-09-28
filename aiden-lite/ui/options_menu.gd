class_name OptionsMenu
extends Control
## Overlay with Audio / Video / Controls tabs (incl. key rebinding). Saves on Back.
## Created in code by the main menu: add_child(OptionsMenu.new())

signal closed

var _waiting := ""
var _key_buttons := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.85)
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(680, 480)
	center.add_child(panel)
	var vb := VBoxContainer.new()
	panel.add_child(vb)

	var title := Label.new()
	title.text = "Options"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	vb.add_child(title)

	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(tabs)
	tabs.add_child(_build_audio())
	tabs.add_child(_build_video())
	tabs.add_child(_build_controls())

	var back := Button.new()
	back.text = "Back"
	back.pressed.connect(_close)
	vb.add_child(back)


func _build_audio() -> Control:
	var v := VBoxContainer.new()
	v.name = "Audio"
	_row(v, "Master volume", _slider("master_volume", 0.0, 1.0, 0.01))
	_row(v, "Music volume", _slider("music_volume", 0.0, 1.0, 0.01))
	_row(v, "Effects volume", _slider("sfx_volume", 0.0, 1.0, 0.01))
	return v


func _build_video() -> Control:
	var v := VBoxContainer.new()
	v.name = "Video"
	_row(v, "Fullscreen", _check("fullscreen"))
	_row(v, "VSync", _check("vsync"))
	_row(v, "Field of view", _slider("fov", 60.0, 110.0, 1.0))
	return v


func _build_controls() -> Control:
	var v := VBoxContainer.new()
	v.name = "Controls"
	_row(v, "Mouse sensitivity", _slider("mouse_sensitivity", 0.0005, 0.01, 0.0005))
	_row(v, "Invert camera Y", _check("invert_y"))
	for action in Settings.ACTION_LABELS:
		var b := Button.new()
		b.text = Settings.key_text(action)
		b.pressed.connect(_begin_rebind.bind(action))
		_key_buttons[action] = b
		_row(v, Settings.ACTION_LABELS[action], b)
	var reset := Button.new()
	reset.text = "Reset keys to default"
	reset.pressed.connect(_reset_keys)
	v.add_child(reset)
	return v


# ---- helpers -------------------------------------------------------------
func _row(parent: Control, text: String, ctrl: Control) -> void:
	var h := HBoxContainer.new()
	var l := Label.new()
	l.text = text
	l.custom_minimum_size = Vector2(240, 0)
	h.add_child(l)
	ctrl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(ctrl)
	parent.add_child(h)


func _slider(prop: String, min_v: float, max_v: float, step: float) -> HSlider:
	var s := HSlider.new()
	s.min_value = min_v
	s.max_value = max_v
	s.step = step
	s.value = Settings.get(prop)
	s.value_changed.connect(_set_setting.bind(prop))
	return s


func _check(prop: String) -> CheckBox:
	var c := CheckBox.new()
	c.button_pressed = Settings.get(prop)
	c.toggled.connect(_set_setting.bind(prop))
	return c


func _set_setting(value, prop: String) -> void:
	Settings.set(prop, value)
	Settings.apply()


# ---- key rebinding -------------------------------------------------------
func _begin_rebind(action: String) -> void:
	_waiting = action
	_key_buttons[action].text = "Press a key..."


func _reset_keys() -> void:
	Settings.reset_keys()
	for action in _key_buttons:
		_key_buttons[action].text = Settings.key_text(action)


func _input(event: InputEvent) -> void:
	if _waiting != "":
		if event is InputEventKey and event.pressed:
			if event.physical_keycode != KEY_ESCAPE:
				Settings.set_key(_waiting, event.physical_keycode)
			_key_buttons[_waiting].text = Settings.key_text(_waiting)
			_waiting = ""
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()


func _close() -> void:
	Settings.save_settings()
	closed.emit()
	queue_free()
