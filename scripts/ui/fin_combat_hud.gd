class_name FinCombatHud
extends CanvasLayer


var _player: FinPlayer
var _font: SystemFont
var _identity_panel: Panel
var _health_bar: ProgressBar
var _resolve_bar: ProgressBar
var _ward_bar: ProgressBar
var _health_value: Label
var _state_label: Label
var _form_label: Label
var _form_subtitle: Label
var _resource_label: Label
var _mark_label: Label
var _concealment_label: Label
var _encounter_label: Label
var _announcement: Label
var _form_tabs: Array[Panel] = []
var _slot_data: Dictionary = {}
var _announcement_timer := 0.0
var _health_flash := 0.0
var _last_health := FinPlayer.MAX_HEALTH
var _last_form := -1
var _using_gamepad := false


func configure(player: FinPlayer) -> void:
	_player = player


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 50
	_font = SystemFont.new()
	_font.font_names = PackedStringArray(["Bahnschrift", "Aptos Display", "Segoe UI"])

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_identity_panel = _make_panel(Vector2(24.0, 20.0), Vector2(446.0, 208.0), Color(0.012, 0.028, 0.031, 0.96), Color("4b817d"))
	root.add_child(_identity_panel)
	_identity_panel.add_child(_make_label("FIN", Vector2(18.0, 8.0), Vector2(72.0, 38.0), 28, Color("f1e6c3")))
	_identity_panel.add_child(_make_label("SHADOW ARTIFICER", Vector2(88.0, 15.0), Vector2(172.0, 24.0), 12, Color("81cabc")))
	_state_label = _make_label("Free", Vector2(264.0, 14.0), Vector2(162.0, 25.0), 11, Color("dfcb77"), HORIZONTAL_ALIGNMENT_RIGHT)
	_identity_panel.add_child(_state_label)

	_form_label = _make_label("NIGHTBLADE", Vector2(18.0, 43.0), Vector2(188.0, 26.0), 16, Color("a9e2d5"))
	_identity_panel.add_child(_form_label)
	_form_subtitle = _make_label("VEIL / BACKSTAB", Vector2(208.0, 45.0), Vector2(218.0, 22.0), 10, Color("829c99"), HORIZONTAL_ALIGNMENT_RIGHT)
	_identity_panel.add_child(_form_subtitle)

	_identity_panel.add_child(_make_label("HEALTH", Vector2(18.0, 73.0), Vector2(72.0, 18.0), 9, Color("a9bbb9")))
	_health_bar = _make_bar(Vector2(18.0, 92.0), Vector2(300.0, 11.0), Color("df5b65"))
	_identity_panel.add_child(_health_bar)
	_health_value = _make_label("245", Vector2(326.0, 70.0), Vector2(100.0, 26.0), 14, Color("f3eee0"), HORIZONTAL_ALIGNMENT_RIGHT)
	_identity_panel.add_child(_health_value)

	_identity_panel.add_child(_make_label("RESOLVE", Vector2(18.0, 110.0), Vector2(72.0, 16.0), 8, Color("7eb6b2")))
	_resolve_bar = _make_bar(Vector2(18.0, 128.0), Vector2(191.0, 7.0), Color("57c9bd"))
	_identity_panel.add_child(_resolve_bar)
	_identity_panel.add_child(_make_label("WARD", Vector2(221.0, 110.0), Vector2(50.0, 16.0), 8, Color("d3bd69")))
	_ward_bar = _make_bar(Vector2(221.0, 128.0), Vector2(205.0, 7.0), Color("d9bd58"))
	_identity_panel.add_child(_ward_bar)

	_mark_label = _make_label("PIERCE 0", Vector2(18.0, 140.0), Vector2(96.0, 18.0), 9, Color("f0ce68"))
	_identity_panel.add_child(_mark_label)
	_resource_label = _make_label("VEIL READY", Vector2(116.0, 140.0), Vector2(208.0, 18.0), 9, Color("9ed6ca"), HORIZONTAL_ALIGNMENT_CENTER)
	_identity_panel.add_child(_resource_label)
	_concealment_label = _make_label("EXPOSED", Vector2(328.0, 140.0), Vector2(98.0, 18.0), 9, Color("768e8c"), HORIZONTAL_ALIGNMENT_RIGHT)
	_identity_panel.add_child(_concealment_label)

	for form_index: int in FinPlayer.Form.size():
		var tab := _make_panel(
			Vector2(18.0 + float(form_index) * 103.0, 166.0),
			Vector2(96.0, 25.0),
			Color(0.02, 0.04, 0.043, 0.96),
			Color("355b59")
		)
		_identity_panel.add_child(tab)
		tab.add_child(_make_label(
			["NIGHT", "ARBAL", "HUNT", "TOOLS"][form_index],
			Vector2(5.0, 1.0),
			Vector2(86.0, 22.0),
			9,
			Color("adbfbb"),
			HORIZONTAL_ALIGNMENT_CENTER
		))
		_form_tabs.append(tab)

	var encounter_panel := _make_panel(Vector2(500.0, 20.0), Vector2(280.0, 50.0), Color(0.012, 0.028, 0.031, 0.92), Color("4b817d"))
	root.add_child(encounter_panel)
	_encounter_label = _make_label("RELIQUARY  /  WAVE 1", Vector2(12.0, 8.0), Vector2(256.0, 32.0), 16, Color("e7efdd"), HORIZONTAL_ALIGNMENT_CENTER)
	encounter_panel.add_child(_encounter_label)

	_announcement = _make_label("", Vector2(340.0, 94.0), Vector2(600.0, 58.0), 28, Color("f0d56e"), HORIZONTAL_ALIGNMENT_CENTER)
	_announcement.add_theme_color_override(&"font_shadow_color", Color(0.01, 0.025, 0.028, 0.98))
	_announcement.add_theme_constant_override(&"shadow_offset_x", 3)
	_announcement.add_theme_constant_override(&"shadow_offset_y", 4)
	root.add_child(_announcement)

	var slots := [
		[&"primary", "TWIN DAGGERS", "LMB", "RT"],
		[&"signature", "MIND PIERCE", "RMB", "LT"],
		[&"ability_1", "UMBRAL VEIL", "Q", "RB"],
		[&"ability_2", "SHADOW LUNGE", "E", "LB"],
		[&"step", "UMBRAL STEP", "SPACE", "A"],
		[&"ultimate", "CHANGE FORM", "R", "Y"],
	]
	var slot_width := 178.0
	var total_width := slot_width * float(slots.size()) + 8.0 * float(slots.size() - 1)
	var start_x := (1280.0 - total_width) * 0.5
	for index: int in slots.size():
		var slot_info: Array = slots[index]
		root.add_child(_make_ability_slot(
			Vector2(start_x + float(index) * (slot_width + 8.0), 622.0),
			Vector2(slot_width, 74.0),
			slot_info[0] as StringName,
			String(slot_info[1]),
			String(slot_info[2]),
			String(slot_info[3]),
			index == slots.size() - 1
		))
	_refresh_form()


func _process(delta: float) -> void:
	if not is_instance_valid(_player):
		return
	if _player.health < _last_health - 0.1:
		_health_flash = 1.0
	_last_health = _player.health
	_health_flash = maxf(0.0, _health_flash - delta * 3.5)
	_health_bar.modulate = Color.WHITE.lerp(Color(1.0, 0.38, 0.22), _health_flash * 0.52)
	_health_bar.value = (_player.health / FinPlayer.MAX_HEALTH) * 100.0
	_resolve_bar.value = (_player.resolve / FinPlayer.MAX_RESOLVE) * 100.0
	_ward_bar.value = (_player.ward / FinPlayer.MAX_WARD) * 100.0
	_health_value.text = "%d" % int(ceil(_player.health))
	_state_label.text = _player.get_state_label()
	_mark_label.text = "PIERCE %d" % _player.get_total_pierce_marks()
	_concealment_label.text = "CONCEALED" if _player.is_concealed() else "EXPOSED"
	_concealment_label.add_theme_color_override(&"font_color", Color("9be6d2") if _player.is_concealed() else Color("768e8c"))
	if _last_form != _player.get_form():
		_refresh_form()
	_update_resources()
	_update_ability_slots()
	if _using_gamepad != _player.is_using_gamepad():
		_using_gamepad = _player.is_using_gamepad()
		_refresh_glyphs()
	_announcement_timer = maxf(0.0, _announcement_timer - delta)
	_announcement.modulate.a = minf(1.0, _announcement_timer * 3.0)


func _update_resources() -> void:
	match _player.get_form():
		FinPlayer.Form.NIGHTBLADE:
			_resource_label.text = "VEIL READY" if _player.veil_cooldown <= 0.0 else "VEIL %.1f" % _player.veil_cooldown
		FinPlayer.Form.ARBALEST:
			_resource_label.text = "BOLT LOADED" if _player.is_crossbow_loaded() else "RELOADING %.1f" % _player.get_crossbow_reload()
		FinPlayer.Form.HUNTSMAN:
			_resource_label.text = "DAGGERS %d  /  BINDS %d" % [_player.get_throwing_dagger_count(), _player.get_trap_count()]
		FinPlayer.Form.ARTIFICER:
			_resource_label.text = "POTIONS %d  /  SMOKE %d" % [_player.get_potion_count(), _player.get_smoke_bomb_count()]


func _update_ability_slots() -> void:
	var form := _player.get_form()
	match form:
		FinPlayer.Form.NIGHTBLADE:
			_update_slot(&"primary", 0.0, 1.0, "3-HIT COMBO")
			_update_slot(&"signature", 0.0, 1.0, "%d MARKS" % _player.get_total_pierce_marks())
			_update_slot(&"ability_1", _player.veil_cooldown, 8.0, "READY")
			_update_slot(&"ability_2", _player.shadow_lunge_cooldown, 4.2, "READY")
		FinPlayer.Form.ARBALEST:
			_update_slot(&"primary", 0.0 if _player.is_crossbow_loaded() else _player.get_crossbow_reload(), FinPlayer.CROSSBOW_RELOAD_TIME, "LOADED")
			_update_slot(&"signature", 0.0 if _player.is_crossbow_loaded() else _player.get_crossbow_reload(), 3.45, "%d MARKS" % _player.get_total_pierce_marks())
			_update_slot(&"ability_1", _player.quick_crank_cooldown, 5.8, "READY")
			_update_slot(&"ability_2", _player.scatterbolt_cooldown, 5.4, "READY")
		FinPlayer.Form.HUNTSMAN:
			_update_slot(&"primary", 0.0, 1.0, "RANGE BUILDS")
			_update_slot(&"signature", 0.0, 1.0, "HOLD DRAW")
			_update_slot(&"ability_1", _player.shadow_bind_cooldown, 0.72, "%d/2 SET" % _player.get_trap_count())
			_update_slot(&"ability_2", 0.0 if _player.get_throwing_dagger_count() > 0 else FinPlayer.DAGGER_CHARGE_TIME, FinPlayer.DAGGER_CHARGE_TIME, "%d/3" % _player.get_throwing_dagger_count())
		FinPlayer.Form.ARTIFICER:
			_update_slot(&"primary", 0.0, 1.0, "RESOLVE TAP")
			_update_slot(&"signature", _player.mutivarg_cooldown, 8.0, "READY")
			_update_slot(&"ability_1", 0.0 if _player.get_potion_count() > 0 else FinPlayer.POTION_CHARGE_TIME, FinPlayer.POTION_CHARGE_TIME, "%d/3 %s" % [_player.get_potion_count(), _player.get_last_potion_label()])
			_update_slot(&"ability_2", 0.0 if _player.get_smoke_bomb_count() > 0 else FinPlayer.SMOKE_CHARGE_TIME, FinPlayer.SMOKE_CHARGE_TIME, "%d/2" % _player.get_smoke_bomb_count())
	_update_slot(&"step", _player.umbral_step_cooldown, FinPlayer.UMBRAL_STEP_COOLDOWN, "ESCAPE")
	_update_slot(&"ultimate", 0.0, 1.0, "4 FORMS")
	if _player.get_signature_charge_ratio() > 0.0:
		var data: Dictionary = _slot_data[&"signature"]
		(data[&"progress"] as ProgressBar).value = _player.get_signature_charge_ratio() * 100.0
		(data[&"status"] as Label).text = "%d%%" % int(round(_player.get_signature_charge_ratio() * 100.0))


func _refresh_form() -> void:
	if not is_instance_valid(_player):
		return
	_last_form = _player.get_form()
	var accent := _player.get_form_accent()
	_form_label.text = _player.get_form_label()
	_form_label.add_theme_color_override(&"font_color", accent)
	_form_subtitle.text = _player.get_form_subtitle()
	var identity_style := _identity_panel.get_theme_stylebox(&"panel") as StyleBoxFlat
	identity_style.border_color = accent
	for form_index: int in _form_tabs.size():
		var selected := form_index == _last_form
		var style := _form_tabs[form_index].get_theme_stylebox(&"panel") as StyleBoxFlat
		style.bg_color = Color(FinPlayer.FORM_ACCENTS[form_index], 0.26 if selected else 0.035)
		style.border_color = FinPlayer.FORM_ACCENTS[form_index] if selected else Color("355b59")
		style.set_border_width_all(2 if selected else 1)
		var label := _form_tabs[form_index].get_child(0) as Label
		label.add_theme_color_override(&"font_color", Color("f3efdf") if selected else Color("718986"))
	for slot_id: Variant in _slot_data:
		if slot_id == &"ultimate" or slot_id == &"step":
			continue
		var slot_style := (_slot_data[slot_id] as Dictionary)[&"panel_style"] as StyleBoxFlat
		slot_style.border_color = Color(accent, 0.74)
	(_slot_data[&"primary"] as Dictionary)[&"name"].text = _player.get_primary_name()
	(_slot_data[&"signature"] as Dictionary)[&"name"].text = _player.get_signature_name()
	(_slot_data[&"ability_1"] as Dictionary)[&"name"].text = _player.get_ability_1_name()
	(_slot_data[&"ability_2"] as Dictionary)[&"name"].text = _player.get_ability_2_name()


func set_encounter(wave: int, enemies_remaining: int) -> void:
	_encounter_label.text = "RELIQUARY  /  WAVE %d  /  %d REMAIN" % [wave, enemies_remaining]


func announce(message: String) -> void:
	_announcement.text = message
	_announcement.modulate.a = 1.0
	_announcement_timer = 1.45


func _update_slot(slot_id: StringName, remaining: float, maximum: float, ready_text: String) -> void:
	if not _slot_data.has(slot_id):
		return
	var data: Dictionary = _slot_data[slot_id]
	var progress := data[&"progress"] as ProgressBar
	var status := data[&"status"] as Label
	if remaining <= 0.0:
		progress.value = 100.0
		status.text = ready_text
		status.add_theme_color_override(&"font_color", Color("e1d36d"))
	else:
		progress.value = (1.0 - clampf(remaining / maxf(0.01, maximum), 0.0, 1.0)) * 100.0
		status.text = "%.1f" % remaining
		status.add_theme_color_override(&"font_color", Color("829d99"))


func _refresh_glyphs() -> void:
	for slot_id: Variant in _slot_data:
		var data: Dictionary = _slot_data[slot_id]
		(data[&"glyph"] as Label).text = String(data[&"pad"] if _using_gamepad else data[&"keyboard"])


func _make_ability_slot(
	at: Vector2,
	panel_size: Vector2,
	slot_id: StringName,
	ability_name: String,
	keyboard_glyph: String,
	controller_glyph: String,
	is_ultimate: bool
) -> Panel:
	var border := Color("c8af43") if is_ultimate else Color("39736d")
	var panel := _make_panel(at, panel_size, Color(0.012, 0.028, 0.031, 0.97), border)
	var glyph := _make_label(keyboard_glyph, Vector2(9.0, 7.0), Vector2(43.0, 26.0), 12, Color("f1d66c"), HORIZONTAL_ALIGNMENT_CENTER)
	panel.add_child(glyph)
	var name_label := _make_label(ability_name, Vector2(52.0, 7.0), Vector2(panel_size.x - 60.0, 28.0), 9, Color("e5eee6"))
	panel.add_child(name_label)
	var status := _make_label("READY", Vector2(10.0, 38.0), Vector2(panel_size.x - 20.0, 20.0), 9, Color("e1d36d"), HORIZONTAL_ALIGNMENT_RIGHT)
	panel.add_child(status)
	var progress := _make_bar(Vector2(10.0, 61.0), Vector2(panel_size.x - 20.0, 5.0), Color("62c8b5") if not is_ultimate else Color("d5b947"))
	panel.add_child(progress)
	_slot_data[slot_id] = {
		&"glyph": glyph,
		&"name": name_label,
		&"status": status,
		&"progress": progress,
		&"keyboard": keyboard_glyph,
		&"pad": controller_glyph,
		&"panel_style": panel.get_theme_stylebox(&"panel") as StyleBoxFlat,
	}
	return panel


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
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.add_theme_font_override(&"font", _font)
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", color)
	return label


func _make_bar(at: Vector2, bar_size: Vector2, fill: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = 100.0
	bar.value = 100.0
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.custom_minimum_size = Vector2.ZERO
	bar.add_theme_font_size_override(&"font_size", 1)
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.004, 0.012, 0.014, 0.98)
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
	bar.position = at
	bar.size = bar_size
	return bar