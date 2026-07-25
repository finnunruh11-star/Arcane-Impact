class_name SurvivorRunHud
extends CanvasLayer


signal upgrade_selected(upgrade_id: StringName)
signal retry_requested
signal roster_requested

var _hero_name := "HERO"
var _font: SystemFont
var _timer_label: Label
var _level_label: Label
var _status_label: Label
var _upgrade_label: Label
var _xp_bar: ProgressBar
var _xp_label: Label
var _overlay: Control
var _modal_title: Label
var _modal_subtitle: Label
var _choice_buttons: Array[Button] = []
var _retry_button: Button
var _roster_button: Button
var _options: Array[Dictionary] = []
var _mode := StringName()


func configure(hero_name: String) -> void:
	_hero_name = hero_name


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 70
	_font = SystemFont.new()
	_font.font_names = PackedStringArray(["Bahnschrift", "Aptos Display", "Segoe UI"])
	_build_run_display()
	_build_modal()


func set_run_state(run_time: float, level: int, experience: int, required: int, kills: int, enemies: int) -> void:
	var total_seconds := maxi(0, int(floor(run_time)))
	_timer_label.text = "%02d:%02d" % [total_seconds / 60, total_seconds % 60]
	_level_label.text = "LEVEL %d" % level
	_status_label.text = "%d BANISHED   /   %d PRESSING" % [kills, enemies]
	_xp_bar.value = clampf(float(experience) / float(maxi(1, required)) * 100.0, 0.0, 100.0)
	_xp_label.text = "ARCANE ESSENCE  %d / %d" % [experience, required]


func set_upgrade_summary(summary: String) -> void:
	_upgrade_label.text = summary if not summary.is_empty() else "NO BOONS YET"


func show_level_up(options: Array[Dictionary]) -> void:
	_options = options
	_mode = &"upgrade"
	_overlay.visible = true
	_modal_title.text = "LEVEL ASCENDED"
	_modal_subtitle.text = "Choose one boon for %s" % _hero_name
	for index: int in _choice_buttons.size():
		var button := _choice_buttons[index]
		button.visible = index < _options.size()
		if index >= _options.size():
			continue
		var option: Dictionary = _options[index]
		button.text = "%d   %s\n%s" % [index + 1, String(option[&"title"]), String(option[&"description"])]
	_retry_button.visible = false
	_roster_button.visible = false
	if not _choice_buttons.is_empty():
		_choice_buttons[0].grab_focus()


func show_run_end(victory: bool, run_time: float, kills: int, level: int) -> void:
	_options.clear()
	_mode = &"end"
	_overlay.visible = true
	_modal_title.text = "RITUAL SURVIVED" if victory else "THE HORDE CLAIMS YOU"
	var total_seconds := maxi(0, int(floor(run_time)))
	_modal_subtitle.text = "%02d:%02d   /   LEVEL %d   /   %d BANISHED" % [total_seconds / 60, total_seconds % 60, level, kills]
	for button: Button in _choice_buttons:
		button.visible = false
	_retry_button.visible = true
	_roster_button.visible = true
	_retry_button.grab_focus()


func hide_modal() -> void:
	_mode = StringName()
	_options.clear()
	_overlay.visible = false


func is_modal_open() -> bool:
	return _overlay.visible


func _unhandled_input(event: InputEvent) -> void:
	if not _overlay.visible or not event is InputEventKey or not event.pressed or event.echo:
		return
	var key_event := event as InputEventKey
	if _mode == &"upgrade":
		var option_index := -1
		match key_event.physical_keycode:
			KEY_1:
				option_index = 0
			KEY_2:
				option_index = 1
			KEY_3:
				option_index = 2
		if option_index >= 0:
			_choose_upgrade(option_index)
	elif _mode == &"end":
		if key_event.physical_keycode in [KEY_ENTER, KEY_SPACE]:
			retry_requested.emit()
		elif key_event.physical_keycode == KEY_ESCAPE:
			roster_requested.emit()


func _build_run_display() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var run_panel := _make_panel(Vector2(908.0, 22.0), Vector2(348.0, 118.0), Color(0.018, 0.030, 0.036, 0.94), Color("3d756e"))
	root.add_child(run_panel)
	_timer_label = _make_label("00:00", Vector2(18.0, 8.0), Vector2(140.0, 46.0), 32, Color("f4dfb0"))
	run_panel.add_child(_timer_label)
	_level_label = _make_label("LEVEL 1", Vector2(176.0, 12.0), Vector2(154.0, 34.0), 16, Color("74e0bb"), HORIZONTAL_ALIGNMENT_RIGHT)
	run_panel.add_child(_level_label)
	_status_label = _make_label("0 BANISHED   /   0 PRESSING", Vector2(18.0, 54.0), Vector2(312.0, 22.0), 11, Color("b7ccca"))
	run_panel.add_child(_status_label)
	_upgrade_label = _make_label("NO BOONS YET", Vector2(18.0, 82.0), Vector2(312.0, 22.0), 10, Color("839b98"))
	run_panel.add_child(_upgrade_label)

	var xp_panel := _make_panel(Vector2(382.0, 574.0), Vector2(516.0, 38.0), Color(0.018, 0.030, 0.036, 0.94), Color("35746b"))
	root.add_child(xp_panel)
	_xp_bar = _make_bar(Vector2(12.0, 20.0), Vector2(492.0, 7.0), Color("55d7a7"))
	xp_panel.add_child(_xp_bar)
	_xp_label = _make_label("ARCANE ESSENCE  0 / 4", Vector2(12.0, 1.0), Vector2(492.0, 18.0), 10, Color("d9f5e8"), HORIZONTAL_ALIGNMENT_CENTER)
	xp_panel.add_child(_xp_label)


func _build_modal() -> void:
	_overlay = Control.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.visible = false
	add_child(_overlay)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.005, 0.010, 0.012, 0.84)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.add_child(shade)
	var modal := _make_panel(Vector2(250.0, 118.0), Vector2(780.0, 484.0), Color(0.018, 0.031, 0.038, 0.99), Color("58b798"))
	_overlay.add_child(modal)
	_modal_title = _make_label("LEVEL ASCENDED", Vector2(36.0, 24.0), Vector2(708.0, 44.0), 30, Color("f4dfb0"), HORIZONTAL_ALIGNMENT_CENTER)
	modal.add_child(_modal_title)
	_modal_subtitle = _make_label("Choose one boon", Vector2(36.0, 68.0), Vector2(708.0, 28.0), 13, Color("9fb9b4"), HORIZONTAL_ALIGNMENT_CENTER)
	modal.add_child(_modal_subtitle)
	for index: int in 3:
		var button := _make_button(Vector2(52.0, 118.0 + float(index) * 94.0), Vector2(676.0, 76.0), "BOON", Color("4c9f89"))
		button.pressed.connect(func() -> void: _choose_upgrade(index))
		modal.add_child(button)
		_choice_buttons.append(button)
	_retry_button = _make_button(Vector2(138.0, 242.0), Vector2(234.0, 58.0), "RETRY RUN", Color("c58b47"))
	_retry_button.pressed.connect(func() -> void: retry_requested.emit())
	_retry_button.visible = false
	modal.add_child(_retry_button)
	_roster_button = _make_button(Vector2(408.0, 242.0), Vector2(234.0, 58.0), "RETURN TO ROSTER", Color("648f8a"))
	_roster_button.pressed.connect(func() -> void: roster_requested.emit())
	_roster_button.visible = false
	modal.add_child(_roster_button)


func _choose_upgrade(index: int) -> void:
	if _mode != &"upgrade" or index < 0 or index >= _options.size():
		return
	upgrade_selected.emit(StringName(_options[index][&"id"]))


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


func _make_label(text: String, at: Vector2, label_size: Vector2, font_size: int, color: Color, alignment := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.position = at
	label.size = label_size
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.add_theme_font_override(&"font", _font)
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", color)
	return label


func _make_button(at: Vector2, button_size: Vector2, text: String, accent: Color) -> Button:
	var button := Button.new()
	button.position = at
	button.size = button_size
	button.text = text
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_override(&"font", _font)
	button.add_theme_font_size_override(&"font_size", 14)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.028, 0.050, 0.058, 0.98)
	normal.border_color = Color(accent, 0.78)
	normal.set_border_width_all(2)
	normal.corner_radius_top_left = 5
	normal.corner_radius_top_right = 5
	normal.corner_radius_bottom_left = 5
	normal.corner_radius_bottom_right = 5
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(accent, 0.26)
	hover.border_color = accent
	button.add_theme_stylebox_override(&"normal", normal)
	button.add_theme_stylebox_override(&"hover", hover)
	button.add_theme_stylebox_override(&"focus", hover)
	button.add_theme_stylebox_override(&"pressed", hover)
	return button


func _make_bar(at: Vector2, bar_size: Vector2, fill: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.position = at
	bar.size = bar_size
	bar.min_value = 0.0
	bar.max_value = 100.0
	bar.value = 0.0
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.006, 0.012, 0.014, 0.98)
	var foreground := StyleBoxFlat.new()
	foreground.bg_color = fill
	bar.add_theme_stylebox_override(&"background", background)
	bar.add_theme_stylebox_override(&"fill", foreground)
	return bar