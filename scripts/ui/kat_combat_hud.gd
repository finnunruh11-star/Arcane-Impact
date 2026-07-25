class_name KatCombatHud
extends CanvasLayer


var _player: KatPlayer
var _font: SystemFont
var _health_bar: ProgressBar
var _ward_bar: ProgressBar
var _resolve_bar: ProgressBar
var _mana_bar: ProgressBar
var _vitality_bar: ProgressBar
var _health_value: Label
var _mana_value: Label
var _state_label: Label
var _encounter_label: Label
var _announcement: Label
var _announcement_timer := 0.0
var _slot_data: Dictionary = {}
var _using_gamepad := false


func configure(player: KatPlayer) -> void:
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

	var identity_panel := _make_panel(Vector2(24.0, 22.0), Vector2(374.0, 196.0), Color(0.025, 0.038, 0.046, 0.94), Color("814253"))
	root.add_child(identity_panel)
	identity_panel.add_child(_make_label("KAT", Vector2(18.0, 12.0), Vector2(74.0, 35.0), 28, Color("f3d7b1")))
	identity_panel.add_child(_make_label("VAMPIRIC BULWARK", Vector2(92.0, 18.0), Vector2(245.0, 24.0), 13, Color("d06a7c")))
	_state_label = _make_label("Free", Vector2(270.0, 17.0), Vector2(82.0, 24.0), 12, Color("dfb85f"), HORIZONTAL_ALIGNMENT_RIGHT)
	identity_panel.add_child(_state_label)

	identity_panel.add_child(_make_label("HEALTH + WARD", Vector2(18.0, 46.0), Vector2(130.0, 18.0), 9, Color("b8a9a5")))
	_health_bar = _make_bar(Vector2(18.0, 66.0), Vector2(246.0, 11.0), Color("d94b55"))
	identity_panel.add_child(_health_bar)
	_ward_bar = _make_bar(Vector2(18.0, 80.0), Vector2(246.0, 6.0), Color("a967d5"))
	identity_panel.add_child(_ward_bar)
	_resolve_bar = _make_bar(Vector2(18.0, 106.0), Vector2(336.0, 7.0), Color("56c9bd"))
	identity_panel.add_child(_resolve_bar)
	_mana_bar = _make_bar(Vector2(18.0, 136.0), Vector2(246.0, 8.0), Color("6f9ee8"))
	identity_panel.add_child(_mana_bar)
	_vitality_bar = _make_bar(Vector2(18.0, 172.0), Vector2(336.0, 9.0), Color("f0a13d"))
	identity_panel.add_child(_vitality_bar)
	identity_panel.add_child(_make_label("RESOLVE", Vector2(18.0, 88.0), Vector2(80.0, 17.0), 9, Color("829d9b")))
	identity_panel.add_child(_make_label("MANA / SUSTAIN", Vector2(18.0, 117.0), Vector2(130.0, 18.0), 9, Color("91abd7")))
	identity_panel.add_child(_make_label("TITHE OF LIFE", Vector2(18.0, 151.0), Vector2(120.0, 18.0), 10, Color("bda778")))
	_health_value = _make_label("340", Vector2(271.0, 46.0), Vector2(82.0, 22.0), 14, Color("f3e8d8"), HORIZONTAL_ALIGNMENT_RIGHT)
	identity_panel.add_child(_health_value)
	_mana_value = _make_label("120 / 120", Vector2(266.0, 116.0), Vector2(88.0, 20.0), 11, Color("c8d8f4"), HORIZONTAL_ALIGNMENT_RIGHT)
	identity_panel.add_child(_mana_value)

	var encounter_panel := _make_panel(Vector2(500.0, 22.0), Vector2(280.0, 50.0), Color(0.025, 0.038, 0.046, 0.90), Color("42666a"))
	root.add_child(encounter_panel)
	_encounter_label = _make_label("RELIQUARY  /  WAVE 1", Vector2(12.0, 8.0), Vector2(256.0, 32.0), 16, Color("dce7df"), HORIZONTAL_ALIGNMENT_CENTER)
	encounter_panel.add_child(_encounter_label)

	_announcement = _make_label("", Vector2(350.0, 98.0), Vector2(580.0, 56.0), 29, Color("ffe0a0"), HORIZONTAL_ALIGNMENT_CENTER)
	_announcement.add_theme_color_override(&"font_shadow_color", Color(0.08, 0.01, 0.02, 0.95))
	_announcement.add_theme_constant_override(&"shadow_offset_x", 3)
	_announcement.add_theme_constant_override(&"shadow_offset_y", 4)
	root.add_child(_announcement)

	var slots := [
		[&"primary", "GRAVEBELL", "LMB", "RT"],
		[&"guard", "GREATSHIELD", "RMB", "LT"],
		[&"leech", "LEECH CHOIR", "Q", "RB"],
		[&"halo", "MOURNING HALO", "E", "LB"],
		[&"march", "BASTION MARCH", "SPACE", "A"],
		[&"ultimate", "BLACK COMMUNION", "R", "Y"],
	]
	var slot_width := 178.0
	var total_width := slot_width * float(slots.size()) + 8.0 * float(slots.size() - 1)
	var start_x := (1280.0 - total_width) * 0.5
	for index: int in slots.size():
		var slot_info: Array = slots[index]
		var slot_id: StringName = slot_info[0]
		var panel := _make_ability_slot(
			Vector2(start_x + float(index) * (slot_width + 8.0), 622.0),
			Vector2(slot_width, 74.0),
			slot_id,
			String(slot_info[1]),
			String(slot_info[2]),
			String(slot_info[3]),
			index == slots.size() - 1
		)
		root.add_child(panel)


func _process(delta: float) -> void:
	if not is_instance_valid(_player):
		return
	_health_bar.value = (_player.health / _player.get_max_health()) * 100.0
	_ward_bar.value = (_player.ward / KatPlayer.MAX_WARD) * 100.0
	_resolve_bar.value = (_player.resolve / _player.get_max_resolve()) * 100.0
	_mana_bar.value = (_player.mana / _player.get_max_mana()) * 100.0
	_vitality_bar.value = (_player.vitality / KatPlayer.MAX_VITALITY) * 100.0
	_health_value.text = "%d/%d +%d" % [int(ceil(_player.health)), int(ceil(_player.get_max_health())), int(ceil(_player.ward))]
	_mana_value.text = "%d / %d" % [int(floor(_player.mana)), int(ceil(_player.get_max_mana()))]
	_state_label.text = _player.get_state_label()
	_update_slot(&"leech", _player.leech_cooldown, 9.5)
	_update_slot(&"halo", _player.halo_cooldown, 11.5)
	_update_slot(&"march", _player.march_cooldown, 3.6)
	_update_slot(&"ultimate", 0.0 if _player.vitality >= KatPlayer.MAX_VITALITY else 1.0, 1.0)
	_update_slot(&"primary", 0.0, 1.0)
	_update_slot(&"guard", 0.0, 1.0)
	if _player.is_leech_choir_active():
		_set_slot_status(&"leech", "ON  -16 MANA/s", Color("f08aa0"), _mana_bar.value)
	elif _player.leech_cooldown <= 0.0:
		_set_slot_status(&"leech", "TOGGLE  16/s", Color("f6d97d"), 100.0)
	if _player.is_halo_active():
		_set_slot_status(&"halo", "ON  -22 MANA/s", Color("f08aa0"), _mana_bar.value)
	elif _player.halo_cooldown <= 0.0:
		_set_slot_status(&"halo", "TOGGLE  22/s", Color("f6d97d"), 100.0)
	_apply_progression_status(&"guard", &"signature")
	_apply_progression_status(&"leech", &"ability_1")
	_apply_progression_status(&"halo", &"ability_2")
	_apply_progression_status(&"march", &"evade")
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


func _update_slot(slot_id: StringName, remaining: float, maximum: float) -> void:
	if not _slot_data.has(slot_id):
		return
	var data: Dictionary = _slot_data[slot_id]
	var progress := data[&"progress"] as ProgressBar
	var status := data[&"status"] as Label
	if remaining <= 0.0:
		progress.value = 100.0
		status.text = "READY"
		status.add_theme_color_override(&"font_color", Color("f6d97d"))
	else:
		progress.value = (1.0 - clampf(remaining / maximum, 0.0, 1.0)) * 100.0
		status.text = "%.1f" % remaining if maximum > 1.0 else "CHARGE"
		status.add_theme_color_override(&"font_color", Color("8c9d9b"))


func _set_slot_status(slot_id: StringName, text: String, color: Color, progress_value: float) -> void:
	var data: Dictionary = _slot_data[slot_id]
	(data[&"status"] as Label).text = text
	(data[&"status"] as Label).add_theme_color_override(&"font_color", color)
	(data[&"progress"] as ProgressBar).value = progress_value


func _apply_progression_status(display_slot: StringName, progression_slot: StringName) -> void:
	var data: Dictionary = _slot_data[display_slot]
	var status := data[&"status"] as Label
	var progress := data[&"progress"] as ProgressBar
	var glyph := data[&"glyph"] as Label
	if not _player.is_survivor_ability_unlocked(progression_slot):
		status.text = "LOCKED"
		status.add_theme_color_override(&"font_color", Color("64706f"))
		progress.value = 0.0
		glyph.modulate = Color(0.42, 0.46, 0.46, 1.0)
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
	var border := Color("b66e3f") if is_ultimate else Color("4e6263")
	var panel := _make_panel(at, panel_size, Color(0.025, 0.037, 0.043, 0.95), border)
	var glyph := _make_label(keyboard_glyph, Vector2(10.0, 8.0), Vector2(42.0, 25.0), 13, Color("f3d9a5"), HORIZONTAL_ALIGNMENT_CENTER)
	panel.add_child(glyph)
	panel.add_child(_make_label(ability_name, Vector2(52.0, 7.0), Vector2(panel_size.x - 60.0, 28.0), 12, Color("dbe6df")))
	var status := _make_label("READY", Vector2(10.0, 38.0), Vector2(panel_size.x - 20.0, 20.0), 10, Color("f6d97d"), HORIZONTAL_ALIGNMENT_RIGHT)
	panel.add_child(status)
	var progress := _make_bar(Vector2(10.0, 61.0), Vector2(panel_size.x - 20.0, 5.0), Color("d15a64") if not is_ultimate else Color("eda642"))
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
	background.bg_color = Color(0.008, 0.014, 0.017, 0.96)
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