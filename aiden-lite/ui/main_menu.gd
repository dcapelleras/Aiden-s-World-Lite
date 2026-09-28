extends Control
## Main menu: New Game / Continue / Options / Credits / Exit. Buttons are built in code.
## Decorate by adding a TextureRect background etc. as siblings in main_menu.tscn (put them ABOVE in the tree),
## or assign a Theme to the root node.

@export var menu_title := ""       # empty = project name
@export var music: AudioStream

var _confirm: ConfirmationDialog


func _ready() -> void:
	Journal.enabled = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = false

	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	vb.custom_minimum_size = Vector2(280, 0)
	center.add_child(vb)

	var title := Label.new()
	title.text = menu_title if menu_title != "" else str(ProjectSettings.get_setting("application/config/name"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	vb.add_child(title)

	var first := _add_button(vb, "New Game", _on_new_game)
	var cont := _add_button(vb, "Continue", _on_continue)
	cont.disabled = not GameState.has_save()
	_add_button(vb, "Options", _on_options)
	_add_button(vb, "Credits", _on_credits)
	_add_button(vb, "Exit Game", _on_exit)
	first.grab_focus()

	_confirm = ConfirmationDialog.new()
	_confirm.dialog_text = "Start a new game?\nAll progress and collectibles will be erased."
	_confirm.confirmed.connect(GameState.new_game)
	add_child(_confirm)

	if music:
		var p := AudioStreamPlayer.new()
		p.stream = music
		p.bus = "Music"
		add_child(p)
		p.play()


func _add_button(parent: Control, text: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 44)
	b.pressed.connect(callback)
	parent.add_child(b)
	return b


func _on_new_game() -> void:
	if GameState.has_save():
		_confirm.popup_centered()
	else:
		GameState.new_game()


func _on_continue() -> void:
	GameState.continue_game()


func _on_options() -> void:
	var menu := OptionsMenu.new()
	add_child(menu)


func _on_credits() -> void:
	GameState.change_scene(GameData.CREDITS_SCENE)


func _on_exit() -> void:
	get_tree().quit()
