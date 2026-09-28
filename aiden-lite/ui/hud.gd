class_name Hud
extends CanvasLayer
## Built entirely in code: meter bar (top-left), controls hint and a red KO flash overlay.
## Restyle by assigning a Theme, or edit _ready().

var _bar: ProgressBar
var _ko: ColorRect


func _ready() -> void:
	add_to_group("hud")
	layer = 10

	var margin := MarginContainer.new()
	for side in ["left", "top"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)
	var vb := VBoxContainer.new()
	margin.add_child(vb)

	_bar = ProgressBar.new()
	_bar.custom_minimum_size = Vector2(320, 22)
	_bar.max_value = GameState.MAX_METER
	_bar.value = GameState.meter
	_bar.show_percentage = false
	vb.add_child(_bar)

	var hint := Label.new()
	hint.text = "[E] Interact    [J] Journal"
	vb.add_child(hint)

	_ko = ColorRect.new()
	_ko.color = Color(0.6, 0, 0, 0)
	_ko.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_ko)
	_ko.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	GameState.meter_changed.connect(_on_meter_changed)


func _on_meter_changed(value: float, _max_value: float) -> void:
	create_tween().tween_property(_bar, "value", value, 0.25)


func flash_ko(duration: float) -> void:
	var t := create_tween()
	t.tween_property(_ko, "color:a", 0.65, 0.3)
	t.tween_interval(maxf(duration - 0.6, 0.0))
	t.tween_property(_ko, "color:a", 0.0, 0.3)
