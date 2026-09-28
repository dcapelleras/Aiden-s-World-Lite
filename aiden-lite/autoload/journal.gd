extends CanvasLayer
## AUTOLOAD "Journal"
## Always-accessible collectibles menu. Toggle with the "journal" action (J by default).
## Uncollected entries are grey and disabled; collected ones are colored and readable.
## When a new collectible is picked up the journal opens on that entry automatically.
## The UI is built in code; restyle it by assigning a Theme, or replace _build() with your own scene.

var enabled := true   # cinematics set this to false
var is_open := false

var _root: Control
var _list: VBoxContainer
var _title: Label
var _icon: TextureRect
var _body: RichTextLabel
var _prev_mouse := Input.MOUSE_MODE_VISIBLE


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_root.hide()
	GameState.collectible_unlocked.connect(_on_unlocked)
	GameState.progress_changed.connect(_refresh)
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if not enabled:
		return
	if event.is_action_pressed("journal"):
		if is_open:
			close_journal()
		else:
			open_journal()
		get_viewport().set_input_as_handled()
	elif is_open and event.is_action_pressed("ui_cancel"):
		close_journal()
		get_viewport().set_input_as_handled()


func open_journal() -> void:
	if is_open:
		return
	is_open = true
	_prev_mouse = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true
	_root.show()


func close_journal() -> void:
	if not is_open:
		return
	is_open = false
	_root.hide()
	get_tree().paused = false
	Input.mouse_mode = _prev_mouse


func show_entry(id: String) -> void:
	for entry in GameData.COLLECTIBLES:
		if entry["id"] == id:
			var got := GameState.is_collected(id)
			_title.text = entry["title"] if got else "???"
			_body.text = entry["text"] if got else "Not discovered yet."
			_icon.texture = _load_icon(entry) if got else null
			return


func _on_unlocked(id: String) -> void:
	_refresh()
	if enabled:
		open_journal()
		show_entry(id)


func _refresh() -> void:
	for c in _list.get_children():
		c.queue_free()
	var first_collected := ""
	for entry in GameData.COLLECTIBLES:
		var id: String = entry["id"]
		var got := GameState.is_collected(id)
		var b := Button.new()
		b.text = entry["title"] if got else "???"
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(0, 48)
		b.expand_icon = true
		b.icon = _load_icon(entry)
		b.disabled = not got
		b.modulate = Color.WHITE if got else Color(0.45, 0.45, 0.45)
		if got:
			b.pressed.connect(show_entry.bind(id))
			if first_collected == "":
				first_collected = id
		_list.add_child(b)
	if first_collected != "":
		show_entry(first_collected)
	else:
		_title.text = "Journal"
		_body.text = "Collect items to unlock entries."
		_icon.texture = null


func _load_icon(entry: Dictionary) -> Texture2D:
	var p: String = entry.get("icon", "")
	if p != "" and ResourceLoader.exists(p):
		return load(p)
	return null


func _build() -> void:
	_root = Control.new()
	add_child(_root)
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.8)
	_root.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var margin := MarginContainer.new()
	_root.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 70)

	var panel := PanelContainer.new()
	margin.add_child(panel)
	var outer := VBoxContainer.new()
	panel.add_child(outer)

	var hb := HBoxContainer.new()
	hb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(hb)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(300, 0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	hb.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(right)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 32)
	right.add_child(_title)
	_icon = TextureRect.new()
	_icon.custom_minimum_size = Vector2(0, 220)
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	right.add_child(_icon)
	_body = RichTextLabel.new()
	_body.bbcode_enabled = true
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(_body)

	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.pressed.connect(close_journal)
	outer.add_child(close_btn)
