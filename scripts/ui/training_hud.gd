class_name TrainingHud
extends CanvasLayer


signal level_requested(level: int)
signal reset_requested
signal roster_requested

var _level_label: Label
var _font: SystemFont
var _accent := Color("62d9cf")


func configure(hero_name: String, accent: Color) -> void:
	name = "%sTrainingHud" % hero_name
	_accent = accent


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 80
	_font = SystemFont.new()
	_font.font_names = PackedStringArray(["Bahnschrift", "Aptos Display", "Segoe UI"])

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var panel := Panel.new()
	panel.position = Vector2(800.0, 22.0)
	panel.size = Vector2(452.0, 102.0)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.018, 0.032, 0.040, 0.96)
	style.border_color = Color(_accent, 0.72)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	panel.add_theme_stylebox_override(&"panel", style)
	root.add_child(panel)

	panel.add_child(_make_label("TRAINING", Vector2(14.0, 8.0), Vector2(92.0, 36.0), 13, _accent))
	_level_label = _make_label("LEVEL 1", Vector2(102.0, 8.0), Vector2(88.0, 36.0), 15, Color("f4dfb0"), HORIZONTAL_ALIGNMENT_CENTER)
	panel.add_child(_level_label)
	var reset := _make_button(Vector2(254.0, 8.0), Vector2(86.0, 36.0), "RESET")
	reset.pressed.connect(func() -> void: reset_requested.emit())
	panel.add_child(reset)
	var roster := _make_button(Vector2(348.0, 8.0), Vector2(90.0, 36.0), "ROSTER")
	roster.pressed.connect(func() -> void: roster_requested.emit())
	panel.add_child(roster)
	var presets := [1, 5, 10, 15, 20]
	for index: int in presets.size():
		var level: int = presets[index]
		var button := _make_button(Vector2(14.0 + float(index) * 46.0, 56.0), Vector2(40.0, 34.0), str(level))
		button.pressed.connect(func() -> void: level_requested.emit(level))
		panel.add_child(button)
	var lower := _make_button(Vector2(254.0, 56.0), Vector2(40.0, 34.0), "-")
	lower.pressed.connect(func() -> void: level_requested.emit(-1))
	panel.add_child(lower)
	var raise := _make_button(Vector2(302.0, 56.0), Vector2(40.0, 34.0), "+")
	raise.pressed.connect(func() -> void: level_requested.emit(-2))
	panel.add_child(raise)
	panel.add_child(_make_label("PAGE UP / DOWN", Vector2(350.0, 56.0), Vector2(88.0, 34.0), 9, Color("8aa6a7"), HORIZONTAL_ALIGNMENT_CENTER))


func set_level(level: int) -> void:
	if is_instance_valid(_level_label):
		_level_label.text = "LEVEL %d" % level


func _make_label(text: String, at: Vector2, label_size: Vector2, font_size: int, color: Color, alignment := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.position = at
	label.size = label_size
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override(&"font", _font)
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", color)
	return label


func _make_button(at: Vector2, button_size: Vector2, text: String) -> Button:
	var button := Button.new()
	button.position = at
	button.size = button_size
	button.text = text
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_override(&"font", _font)
	button.add_theme_font_size_override(&"font_size", 12)
	button.add_theme_color_override(&"font_color", Color("e9f2ed"))
	button.add_theme_color_override(&"font_hover_color", Color.WHITE)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.055, 0.085, 0.098, 0.98)
	normal.border_color = Color(_accent, 0.45)
	normal.set_border_width_all(1)
	normal.corner_radius_top_left = 4
	normal.corner_radius_top_right = 4
	normal.corner_radius_bottom_left = 4
	normal.corner_radius_bottom_right = 4
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(_accent, 0.28)
	button.add_theme_stylebox_override(&"normal", normal)
	button.add_theme_stylebox_override(&"hover", hover)
	button.add_theme_stylebox_override(&"pressed", hover)
	button.add_theme_stylebox_override(&"focus", hover)
	return button