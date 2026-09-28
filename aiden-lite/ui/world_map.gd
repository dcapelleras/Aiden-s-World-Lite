extends Control
## Classic 2D level map. Level buttons are placed at GameData.LEVELS[i]["map_pos"].
## Locked levels are grey and disabled; a marker hops between unlocked levels.
## Controls: arrows / WASD-style ui actions to move, Enter/Space to play, Esc = back to menu, or click.
## Set `background` (and optionally `avatar_texture`) in the inspector of world_map.tscn.

@export var background: Texture2D
@export var avatar_texture: Texture2D
@export var music: AudioStream
@export var node_size := Vector2(72, 72)
@export var unlocked_color := Color(1, 1, 1)
@export var locked_color := Color(0.35, 0.35, 0.35)

var _selected := 0
var _centers: Array[Vector2] = []
var _avatar: Control
var _name_label: Label


func _ready() -> void:
	Journal.enabled = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = false
	var levels: Array = GameData.LEVELS

	if background:
		var bg := TextureRect.new()
		bg.texture = background
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		add_child(bg)
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	for lvl in levels:
		_centers.append(lvl["map_pos"])

	# Paths between levels
	for i in range(levels.size() - 1):
		var line := Line2D.new()
		line.width = 6.0
		line.default_color = unlocked_color if i + 1 < GameState.unlocked_levels else locked_color
		line.points = PackedVector2Array([_centers[i], _centers[i + 1]])
		add_child(line)

	# Level buttons
	for i in levels.size():
		var b := Button.new()
		b.text = str(i + 1)
		b.tooltip_text = levels[i]["name"]
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = node_size
		b.size = node_size
		b.position = _centers[i] - node_size / 2.0
		var unlocked := i < GameState.unlocked_levels
		b.disabled = not unlocked
		b.modulate = unlocked_color if unlocked else locked_color
		b.pressed.connect(_play.bind(i))
		add_child(b)

	# Avatar marker
	if avatar_texture:
		var tr := TextureRect.new()
		tr.texture = avatar_texture
		tr.size = avatar_texture.get_size()
		_avatar = tr
	else:
		var cr := ColorRect.new()
		cr.color = Color(1.0, 0.8, 0.2)
		cr.size = Vector2(28, 28)
		_avatar = cr
	add_child(_avatar)

	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 32)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_name_label)
	_name_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_name_label.offset_top = -80.0

	var back := Button.new()
	back.text = "Main menu"
	back.position = Vector2(20, 20)
	back.focus_mode = Control.FOCUS_NONE
	back.pressed.connect(_back)
	add_child(back)

	_selected = clampi(GameState.unlocked_levels - 1, 0, levels.size() - 1)
	_avatar.position = _avatar_pos(_selected)
	_update_label()

	if music:
		var p := AudioStreamPlayer.new()
		p.stream = music
		p.bus = "Music"
		add_child(p)
		p.play()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_right") or event.is_action_pressed("ui_down"):
		_select(_selected + 1)
	elif event.is_action_pressed("ui_left") or event.is_action_pressed("ui_up"):
		_select(_selected - 1)
	elif event.is_action_pressed("ui_accept"):
		_play(_selected)
	elif event.is_action_pressed("ui_cancel"):
		_back()


func _avatar_pos(i: int) -> Vector2:
	return _centers[i] - _avatar.size / 2.0 - Vector2(0, node_size.y * 0.8)


func _select(i: int) -> void:
	var n := clampi(i, 0, GameState.unlocked_levels - 1)
	if n == _selected:
		return
	_selected = n
	create_tween().tween_property(_avatar, "position", _avatar_pos(n), 0.25) \
			.set_trans(Tween.TRANS_QUAD)
	_update_label()


func _update_label() -> void:
	_name_label.text = GameData.LEVELS[_selected]["name"]


func _play(i: int) -> void:
	GameState.start_level(i)


func _back() -> void:
	GameState.change_scene(GameData.MENU_SCENE)
