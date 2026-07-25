class_name NadCombatHud
extends CanvasLayer


var _player: NadPlayer
var _font: SystemFont
var _health_bar: ProgressBar
var _resolve_bar: ProgressBar
var _mana_bar: ProgressBar
var _health_value: Label
var _mana_value: Label
var _state_label: Label
var _focus_label: Label
var _encounter_label: Label
var _announcement: Label
var _anchor_pips: Array[Panel] = []
var _announcement_timer := 0.0
var _health_flash := 0.0
var _last_health := NadPlayer.MAX_HEALTH
var _slot_data: Dictionary = {}
var _using_gamepad := false


func configure(player: NadPlayer) -> void:
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

	var identity_panel := _make_panel(Vector2(24.0, 22.0), Vector2(410.0, 190.0), Color(0.014, 0.043, 0.048, 0.95), Color("3a9ca0"))
	root.add_child(identity_panel)
	identity_panel.add_child(_make_label("NAD", Vector2(18.0, 10.0), Vector2(84.0, 38.0), 28, Color("ecf5b0")))
	identity_panel.add_child(_make_label("ELDRITCH TACTICIAN", Vector2(96.0, 17.0), Vector2(190.0, 24.0), 13, Color("6fe6e0")))
	_state_label = _make_label("Free", Vector2(282.0, 17.0), Vector2(108.0, 24.0), 12, Color("d9ee79"), HORIZONTAL_ALIGNMENT_RIGHT)
	identity_panel.add_child(_state_label)

	identity_panel.add_child(_make_label("HEALTH", Vector2(18.0, 47.0), Vector2(86.0, 18.0), 9, Color("a8c9c7")))
	_health_bar = _make_bar(Vector2(18.0, 67.0), Vector2(274.0, 11.0), Color("df5b65"))
	identity_panel.add_child(_health_bar)
	_health_value = _make_label("220", Vector2(302.0, 47.0), Vector2(88.0, 24.0), 14, Color("f3eee0"), HORIZONTAL_ALIGNMENT_RIGHT)
	identity_panel.add_child(_health_value)

	identity_panel.add_child(_make_label("RESOLVE", Vector2(18.0, 87.0), Vector2(80.0, 17.0), 9, Color("86b5b5")))
	_resolve_bar = _make_bar(Vector2(18.0, 105.0), Vector2(372.0, 7.0), Color("55d6ce"))
	identity_panel.add_child(_resolve_bar)
	identity_panel.add_child(_make_label("MANA / VEIL PRESSURE", Vector2(18.0, 118.0), Vector2(176.0, 17.0), 9, Color("8edbd7")))
	_mana_bar = _make_bar(Vector2(18.0, 136.0), Vector2(274.0, 10.0), Color("70d8ad"))
	identity_panel.add_child(_mana_bar)
	_mana_value = _make_label("100", Vector2(302.0, 116.0), Vector2(88.0, 24.0), 13, Color("dcf6af"), HORIZONTAL_ALIGNMENT_RIGHT)
	identity_panel.add_child(_mana_value)

	_focus_label = _make_label("FOCUS 0  /  LOCKED 0", Vector2(18.0, 155.0), Vector2(210.0, 22.0), 10, Color("8ce9e4"))
	identity_panel.add_child(_focus_label)
	identity_panel.add_child(_make_label("ANCHORS", Vector2(236.0, 155.0), Vector2(66.0, 22.0), 9, Color("b9d37a")))
	for anchor_index: int in 5:
		var pip := _make_panel(Vector2(285.0 + float(anchor_index) * 21.0, 158.0), Vector2(16.0, 14.0), Color("10272a"), Color("36676a"))
		identity_panel.add_child(pip)
		_anchor_pips.append(pip)

	var encounter_panel := _make_panel(Vector2(500.0, 22.0), Vector2(280.0, 50.0), Color(0.014, 0.043, 0.048, 0.92), Color("3a9ca0"))
	root.add_child(encounter_panel)
	_encounter_label = _make_label("RELIQUARY  /  WAVE 1", Vector2(12.0, 8.0), Vector2(256.0, 32.0), 16, Color("e3f4e9"), HORIZONTAL_ALIGNMENT_CENTER)
	encounter_panel.add_child(_encounter_label)

	_announcement = _make_label("", Vector2(350.0, 98.0), Vector2(580.0, 56.0), 29, Color("eeff9f"), HORIZONTAL_ALIGNMENT_CENTER)
	_announcement.add_theme_color_override(&"font_shadow_color", Color(0.01, 0.05, 0.06, 0.96))
	_announcement.add_theme_constant_override(&"shadow_offset_x", 3)
	_announcement.add_theme_constant_override(&"shadow_offset_y", 4)
	root.add_child(_announcement)

	var slots := [
		[&"primary", "FORESEE", "LMB", "RT"],
		[&"mantle", "ELDRITCH MANTLE", "RMB", "LT"],
		[&"anchor", "TERRAIN ANCHOR", "Q", "RB"],
		[&"cascade", "MENTAL CASCADE", "E", "LB"],
		[&"fold", "FOLD SPACE", "SPACE", "A"],
		[&"ultimate", "ARCANE CONDUIT", "R", "Y"],
	]
	var slot_width := 178.0
	var total_width := slot_width * float(slots.size()) + 8.0 * float(slots.size() - 1)
	var start_x := (1280.0 - total_width) * 0.5
	for index: int in slots.size():
		var slot_info: Array = slots[index]
		var slot_id: StringName = slot_info[0]
		root.add_child(_make_ability_slot(
			Vector2(start_x + float(index) * (slot_width + 8.0), 622.0),
			Vector2(slot_width, 74.0),
			slot_id,
			String(slot_info[1]),
			String(slot_info[2]),
			String(slot_info[3]),
			index == slots.size() - 1
		))


func _process(delta: float) -> void:
	if not is_instance_valid(_player):
		return
	if _player.health < _last_health - 0.1:
		_health_flash = 1.0
	_last_health = _player.health
	_health_flash = maxf(0.0, _health_flash - delta * 3.5)
	_health_bar.modulate = Color.WHITE.lerp(Color(1.0, 0.37, 0.22), _health_flash * 0.52)
	_health_bar.value = (_player.health / _player.get_max_health()) * 100.0
	_resolve_bar.value = (_player.resolve / _player.get_max_resolve()) * 100.0
	_mana_bar.value = (_player.mana / _player.get_max_mana()) * 100.0
	_health_value.text = "%d / %d" % [int(ceil(_player.health)), int(ceil(_player.get_max_health()))]
	_mana_value.text = "%d / %d" % [int(floor(_player.mana)), int(ceil(_player.get_max_mana()))]
	_state_label.text = _player.get_state_label()

	var focus_total := 0
	var locked_count := 0
	for node: Node in get_tree().get_nodes_in_group(&"enemies"):
		if not node.has_method(&"get_mental_focus"):
			continue
		focus_total += int(node.call(&"get_mental_focus"))
		if bool(node.call(&"is_control_locked")):
			locked_count += 1
	_focus_label.text = "FOCUS %d  /  LOCKED %d" % [focus_total, locked_count]
	var anchor_tier := _player.get_survivor_ability_tier(&"ability_1")
	var anchor_capacity := [1, 2, 3, 4, 5][anchor_tier - 1] as int
	if not _player.is_survivor_ability_unlocked(&"ability_1"):
		anchor_capacity = 0
	for anchor_index: int in _anchor_pips.size():
		var active := anchor_index < _player.get_anchor_count()
		var available := anchor_index < anchor_capacity
		var style := _anchor_pips[anchor_index].get_theme_stylebox(&"panel") as StyleBoxFlat
		style.bg_color = Color("c7e66c") if active else Color("10272a")
		style.border_color = Color("8cfff2") if active else (Color("36676a") if available else Color("1c3335"))

	_update_slot(&"primary", 0.0, 1.0, "7 MANA")
	_update_slot(&"mantle", 0.0, 1.0, "32 MANA")
	_update_slot(&"anchor", _player.anchor_cooldown, 8.0, "COLLAPSE" if _player.get_anchor_count() == anchor_capacity else "%d/%d  18 MANA" % [_player.get_anchor_count(), anchor_capacity])
	_update_slot(&"cascade", _player.cascade_cooldown, 6.5, "24 MANA")
	_update_slot(&"fold", _player.fold_cooldown, 2.8, "14 MANA")
	_update_slot(&"ultimate", _player.ultimate_cooldown, 22.0, "50 MANA")
	if _player.is_mantle_charging():
		var data: Dictionary = _slot_data[&"mantle"]
		var progress := data[&"progress"] as ProgressBar
		var status := data[&"status"] as Label
		progress.value = _player.get_mantle_charge_ratio() * 100.0
		status.text = "%d%%" % int(round(_player.get_mantle_charge_ratio() * 100.0))
	_apply_progression_status(&"mantle", &"signature")
	_apply_progression_status(&"anchor", &"ability_1")
	_apply_progression_status(&"cascade", &"ability_2")
	_apply_progression_status(&"fold", &"evade")
	_apply_progression_status(&"ultimate", &"ultimate")

	if _using_gamepad != _player.is_using_gamepad():
		_using_gamepad = _player.is_using_gamepad()
		_refresh_glyphs()
	_announcement_timer = maxf(0.0, _announcement_timer - delta)
	_announcement.modulate.a = minf(1.0, _announcement_timer * 3.0)


func set_encounter(wave: int, enemies_remaining: int) -> void:
	_encounter_label.text = "RELIQUARY  /  WAVE %d  /  %d REMAIN" % [wave, enemies_remaining]


func set_survivor_encounter(level: int, enemies_alive: int) -> void:
	_encounter_label.text = "HORDE  /  LV.%d  /  %d ACTIVE" % [level, enemies_alive]


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
		status.add_theme_color_override(&"font_color", Color("def178"))
	else:
		progress.value = (1.0 - clampf(remaining / maximum, 0.0, 1.0)) * 100.0
		status.text = "%.1f" % remaining
		status.add_theme_color_override(&"font_color", Color("88aaa8"))


func _apply_progression_status(display_slot: StringName, progression_slot: StringName) -> void:
	var data: Dictionary = _slot_data[display_slot]
	var status := data[&"status"] as Label
	var progress := data[&"progress"] as ProgressBar
	var glyph := data[&"glyph"] as Label
	if not _player.is_survivor_ability_unlocked(progression_slot):
		status.text = "LOCKED"
		status.add_theme_color_override(&"font_color", Color("617473"))
		progress.value = 0.0
		glyph.modulate = Color(0.42, 0.48, 0.47, 1.0)
		return
	var rank := _player.get_survivor_ability_rank(progression_slot)
	if rank > 0:
		status.text = "T%d R%d  %s" % [_player.get_survivor_ability_tier(progression_slot), rank, status.text]
	glyph.modulate = Color.WHITE


func _refresh_glyphs() -> void:
	for slot_id: Variant in _slot_data:
		var data: Dictionary = _slot_data[slot_id]
		var glyph := data[&"glyph"] as Label
		glyph.text = String(data[&"pad"] if _using_gamepad else data[&"keyboard"])


func _make_ability_slot(
	at: Vector2,
	panel_size: Vector2,
	slot_id: StringName,
	ability_name: String,
	keyboard_glyph: String,
	controller_glyph: String,
	is_ultimate: bool
) -> Panel:
	var border := Color("b6be43") if is_ultimate else Color("397e80")
	var panel := _make_panel(at, panel_size, Color(0.014, 0.040, 0.044, 0.96), border)
	var glyph := _make_label(keyboard_glyph, Vector2(10.0, 8.0), Vector2(42.0, 25.0), 13, Color("eff5a0"), HORIZONTAL_ALIGNMENT_CENTER)
	panel.add_child(glyph)
	panel.add_child(_make_label(ability_name, Vector2(52.0, 7.0), Vector2(panel_size.x - 60.0, 28.0), 10, Color("e2f4ea")))
	var status := _make_label("READY", Vector2(10.0, 38.0), Vector2(panel_size.x - 20.0, 20.0), 10, Color("def178"), HORIZONTAL_ALIGNMENT_RIGHT)
	panel.add_child(status)
	var progress := _make_bar(Vector2(10.0, 61.0), Vector2(panel_size.x - 20.0, 5.0), Color("60d2b2") if not is_ultimate else Color("ced846"))
	panel.add_child(progress)
	_slot_data[slot_id] = {
		&"glyph": glyph,
		&"status": status,
		&"progress": progress,
		&"keyboard": keyboard_glyph,
		&"pad": controller_glyph,
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
	background.bg_color = Color(0.005, 0.017, 0.018, 0.98)
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
