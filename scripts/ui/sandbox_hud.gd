class_name SandboxHud
extends CanvasLayer


var _player: PrototypePlayer
var _dummy: TargetDummy
var _state_label: Label
var _charge_bar: ProgressBar
var _health_bar: ProgressBar
var _resolve_bar: ProgressBar
var _health_value: Label
var _resolve_value: Label
var _device_label: Label
var _impact_label: Label
var _impact_timer := 0.0
var _font: SystemFont


func configure(player: PrototypePlayer, dummy: TargetDummy) -> void:
	_player = player
	_dummy = dummy


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 50
	_font = SystemFont.new()
	_font.font_names = PackedStringArray(["Bahnschrift", "Aptos", "Segoe UI"])

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var left_panel := _make_panel(Vector2(28.0, 24.0), Vector2(324.0, 128.0), Color(0.035, 0.055, 0.064, 0.92), Color("4a686b"))
	root.add_child(left_panel)
	left_panel.add_child(_make_label("COMBAT LAB 01", Vector2(18.0, 12.0), Vector2(200.0, 24.0), 14, Color("62d9cf")))
	left_panel.add_child(_make_label("VANGUARD PROTOTYPE", Vector2(18.0, 34.0), Vector2(280.0, 30.0), 21, Color("e7eee9")))
	_state_label = _make_label("Free", Vector2(18.0, 70.0), Vector2(110.0, 26.0), 15, Color("f3c869"))
	left_panel.add_child(_state_label)
	_charge_bar = _make_bar(Vector2(18.0, 101.0), Vector2(288.0, 9.0), Color("f05b47"))
	left_panel.add_child(_charge_bar)

	var right_panel := _make_panel(Vector2(928.0, 24.0), Vector2(324.0, 128.0), Color(0.035, 0.055, 0.064, 0.92), Color("665d50"))
	root.add_child(right_panel)
	right_panel.add_child(_make_label("RELIQUARY TEST FRAME", Vector2(18.0, 12.0), Vector2(280.0, 25.0), 16, Color("e8d9b6")))
	_health_bar = _make_bar(Vector2(18.0, 50.0), Vector2(220.0, 11.0), Color("e65b49"))
	right_panel.add_child(_health_bar)
	_resolve_bar = _make_bar(Vector2(18.0, 83.0), Vector2(220.0, 11.0), Color("54d4ce"))
	right_panel.add_child(_resolve_bar)
	right_panel.add_child(_make_label("HEALTH", Vector2(18.0, 32.0), Vector2(90.0, 18.0), 11, Color("adbbb7")))
	right_panel.add_child(_make_label("RESOLVE", Vector2(18.0, 65.0), Vector2(90.0, 18.0), 11, Color("adbbb7")))
	_health_value = _make_label("260", Vector2(245.0, 42.0), Vector2(60.0, 28.0), 15, Color("f2e7d6"), HORIZONTAL_ALIGNMENT_RIGHT)
	_resolve_value = _make_label("150", Vector2(245.0, 75.0), Vector2(60.0, 28.0), 15, Color("f2e7d6"), HORIZONTAL_ALIGNMENT_RIGHT)
	right_panel.add_child(_health_value)
	right_panel.add_child(_resolve_value)

	_device_label = _make_label("KEYBOARD + MOUSE", Vector2(28.0, 668.0), Vector2(250.0, 26.0), 12, Color(0.68, 0.76, 0.74, 0.76))
	root.add_child(_device_label)
	_impact_label = _make_label("", Vector2(430.0, 34.0), Vector2(420.0, 42.0), 24, Color("fff0b0"), HORIZONTAL_ALIGNMENT_CENTER)
	root.add_child(_impact_label)


func _process(delta: float) -> void:
	if not is_instance_valid(_player) or not is_instance_valid(_dummy):
		return
	_state_label.text = _player.get_state_label()
	_charge_bar.value = _player.charge_ratio * 100.0
	_health_bar.value = (_dummy.health / TargetDummy.MAX_HEALTH) * 100.0
	_resolve_bar.value = (_dummy.resolve / TargetDummy.MAX_RESOLVE) * 100.0
	_health_value.text = str(int(ceil(_dummy.health)))
	_resolve_value.text = "BROKEN" if _dummy.is_resolve_broken else str(int(ceil(_dummy.resolve)))
	_device_label.text = "XBOX CONTROLLER" if _player.is_using_gamepad() else "KEYBOARD + MOUSE"

	_impact_timer = maxf(0.0, _impact_timer - delta)
	if _impact_timer <= 0.0:
		_impact_label.modulate.a = move_toward(_impact_label.modulate.a, 0.0, delta * 4.0)


func show_impact(amount: float, _at: Vector2) -> void:
	_impact_label.text = "HEAVY IMPACT  %d" % int(round(amount))
	_impact_label.modulate.a = 1.0
	_impact_timer = 0.48


func _make_panel(at: Vector2, panel_size: Vector2, fill: Color, border: Color) -> Panel:
	var panel := Panel.new()
	panel.position = at
	panel.size = panel_size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	panel.add_theme_stylebox_override(&"panel", style)
	return panel


func _make_label(
	label_text: String,
	at: Vector2,
	label_size: Vector2,
	font_size: int,
	color: Color,
	alignment := HORIZONTAL_ALIGNMENT_LEFT
) -> Label:
	var label := Label.new()
	label.position = at
	label.size = label_size
	label.text = label_text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override(&"font", _font)
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", color)
	return label


func _make_bar(at: Vector2, bar_size: Vector2, fill: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.position = at
	bar.size = bar_size
	bar.min_value = 0.0
	bar.max_value = 100.0
	bar.value = 100.0
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.01, 0.02, 0.025, 0.94)
	background.corner_radius_top_left = 2
	background.corner_radius_top_right = 2
	background.corner_radius_bottom_left = 2
	background.corner_radius_bottom_right = 2
	var foreground := StyleBoxFlat.new()
	foreground.bg_color = fill
	foreground.corner_radius_top_left = 2
	foreground.corner_radius_top_right = 2
	foreground.corner_radius_bottom_left = 2
	foreground.corner_radius_bottom_right = 2
	bar.add_theme_stylebox_override(&"background", background)
	bar.add_theme_stylebox_override(&"fill", foreground)
	return bar