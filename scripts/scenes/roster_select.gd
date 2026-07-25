extends Node2D


const HERO_SCENES := [
	"res://scenes/arena/kat_combat_slice.tscn",
	"res://scenes/arena/sniff_combat_slice.tscn",
	"res://scenes/arena/nad_combat_slice.tscn",
	"res://scenes/arena/fin_combat_slice.tscn",
]
const HERO_CENTERS := [Vector2(172.0, 320.0), Vector2(484.0, 320.0), Vector2(796.0, 320.0), Vector2(1108.0, 320.0)]
const HERO_ACCENTS := [Color("cf5268"), Color("42d7ed"), Color("78d6a6"), Color("dfbd58")]
const HERO_CARD_POSITIONS := [Vector2(24.0, 126.0), Vector2(336.0, 126.0), Vector2(648.0, 126.0), Vector2(960.0, 126.0)]
const HERO_CARD_SIZE := Vector2(296.0, 514.0)

var _selected := 0
var _transitioning := false
var _transition_time := 0.0
var _font: SystemFont
var _panels: Array[Panel] = []
var _buttons: Array[Button] = []
var _heroes: Array[Node2D] = []
var _fade: ColorRect


func _enter_tree() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	InputProfile.ensure_default_bindings()


func _ready() -> void:
	_font = SystemFont.new()
	_font.font_names = PackedStringArray(["Bahnschrift", "Aptos Display", "Segoe UI"])

	var arena := ArenaBackdrop.new()
	arena.name = "ReliquaryBackdrop"
	add_child(arena)

	_build_background()
	_build_hero_previews()
	_build_interface()
	_refresh_selection()
	print("Arcane Impact roster ready.")


func _process(delta: float) -> void:
	if _transitioning:
		_transition_time += delta
		_fade.color.a = clampf(_transition_time / 0.20, 0.0, 1.0)
		if _transition_time >= 0.20:
			get_tree().change_scene_to_file(HERO_SCENES[_selected])
		return
	if Input.is_action_just_pressed(&"move_left") or Input.is_action_just_pressed(&"ui_left"):
		_select(posmod(_selected - 1, HERO_SCENES.size()))
	elif Input.is_action_just_pressed(&"move_right") or Input.is_action_just_pressed(&"ui_right"):
		_select((_selected + 1) % HERO_SCENES.size())
	if Input.is_action_just_pressed(&"ui_accept") or Input.is_action_just_pressed(&"interact"):
		_deploy(_selected)
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	var key_event := event as InputEventKey
	if key_event.physical_keycode == KEY_1:
		_deploy(0)
	elif key_event.physical_keycode == KEY_2:
		_deploy(1)
	elif key_event.physical_keycode == KEY_3:
		_deploy(2)
	elif key_event.physical_keycode == KEY_4:
		_deploy(3)


func _build_background() -> void:
	var background_layer := CanvasLayer.new()
	background_layer.layer = -2
	add_child(background_layer)
	var wash := ColorRect.new()
	wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wash.color = Color(0.015, 0.025, 0.032, 0.70)
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background_layer.add_child(wash)

	var bands := [
		[HERO_CARD_POSITIONS[0], Color(0.18, 0.025, 0.055, 0.22)],
		[HERO_CARD_POSITIONS[1], Color(0.02, 0.20, 0.25, 0.18)],
		[HERO_CARD_POSITIONS[2], Color(0.06, 0.22, 0.16, 0.20)],
		[HERO_CARD_POSITIONS[3], Color(0.22, 0.15, 0.035, 0.19)],
	]
	for band_data: Array in bands:
		var band := ColorRect.new()
		band.position = band_data[0]
		band.size = HERO_CARD_SIZE
		band.color = band_data[1]
		band.mouse_filter = Control.MOUSE_FILTER_IGNORE
		background_layer.add_child(band)


func _build_hero_previews() -> void:
	var kat := KatPlayer.new()
	kat.name = "KatPreview"
	kat.process_mode = Node.PROCESS_MODE_DISABLED
	kat.position = HERO_CENTERS[0]
	kat.aim_direction = Vector2.RIGHT
	kat.scale = Vector2.ONE * 1.72
	add_child(kat)
	var kat_aura := VfxCatalog.spawn_attached(kat, &"kat_absorb", Vector2.ZERO, 0.62, Color(0.90, 0.55, 0.72, 0.38), true)
	kat_aura.z_index = -1
	_heroes.append(kat)

	var sniff := SniffPlayer.new()
	sniff.name = "SniffPreview"
	sniff.process_mode = Node.PROCESS_MODE_DISABLED
	sniff.position = HERO_CENTERS[1]
	sniff.aim_direction = Vector2.LEFT
	sniff.blessing = SniffPlayer.MAX_BLESSING
	sniff.scale = Vector2.ONE * 1.72
	add_child(sniff)
	var sniff_aura := VfxCatalog.spawn_attached(sniff, &"sniff_blessing", Vector2.ZERO, 0.68, Color(0.68, 0.92, 1.0, 0.58), true)
	sniff_aura.z_index = -1
	_heroes.append(sniff)

	var nad := NadPlayer.new()
	nad.name = "NadPreview"
	nad.process_mode = Node.PROCESS_MODE_DISABLED
	nad.position = HERO_CENTERS[2]
	nad.aim_direction = Vector2.LEFT
	nad.scale = Vector2.ONE * 1.72
	add_child(nad)
	_heroes.append(nad)

	var fin := FinPlayer.new()
	fin.name = "FinPreview"
	fin.process_mode = Node.PROCESS_MODE_DISABLED
	fin.position = HERO_CENTERS[3]
	fin.aim_direction = Vector2.LEFT
	fin.scale = Vector2.ONE * 1.62
	add_child(fin)
	var fin_aura := VfxCatalog.spawn_attached(fin, &"fin_shadow", Vector2.ZERO, 0.58, Color(0.34, 0.72, 0.64, 0.38), true)
	fin_aura.z_index = -1
	_heroes.append(fin)


func _build_interface() -> void:
	var ui := CanvasLayer.new()
	ui.layer = 10
	add_child(ui)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(root)

	root.add_child(_make_label("ARCANE IMPACT", Vector2(0.0, 24.0), Vector2(1280.0, 48.0), 34, Color("f4dfb0"), HORIZONTAL_ALIGNMENT_CENTER))
	root.add_child(_make_label("CHOOSE YOUR CATALYST", Vector2(0.0, 70.0), Vector2(1280.0, 28.0), 14, Color("8aa6a7"), HORIZONTAL_ALIGNMENT_CENTER))

	var hero_data := [
		[HERO_CARD_POSITIONS[0], "KAT", "VAMPIRIC BULWARK", "GUARD / DRAIN / COMMAND", HERO_ACCENTS[0], "GRAVEBELL  GREATSHIELD  LEECH CHOIR\nMOURNING HALO  BASTION MARCH  BLACK COMMUNION"],
		[HERO_CARD_POSITIONS[1], "SNIFF", "STORM CATASTROPHIST", "CHAIN / OVERLOAD / DISCHARGE", HERO_ACCENTS[1], "LIGHTNING DART  HEAVENFALL  TEMPEST COVENANT\nCATACLYSM DISCHARGE  FLASHSTEP  WORLDSTORM"],
		[HERO_CARD_POSITIONS[2], "NAD", "ELDRITCH TACTICIAN", "LOCK / ANCHOR / COLLAPSE", HERO_ACCENTS[2], "FORESEE  ELDRITCH MANTLE  TERRAIN ANCHOR\nMENTAL CASCADE  FOLD SPACE  ARCANE CONDUIT"],
		[HERO_CARD_POSITIONS[3], "FIN", "SHADOW ARTIFICER", "SWITCH / PREPARE / EXPLOIT", HERO_ACCENTS[3], "NIGHTBLADE  ARBALEST  HUNTSMAN\nMUTIVARG'S ROD  POTIONS  SMOKE BOMBS"],
	]
	for index: int in hero_data.size():
		var data: Array = hero_data[index]
		var accent: Color = data[4]
		var panel := _make_panel(data[0], HERO_CARD_SIZE, Color(0.012, 0.025, 0.033, 0.72), accent)
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(panel)
		_panels.append(panel)
		panel.add_child(_make_label(String(data[1]), Vector2(24.0, 24.0), Vector2(180.0, 42.0), 29, Color("f6e4bd")))
		panel.add_child(_make_label(String(data[2]), Vector2(24.0, 66.0), Vector2(248.0, 25.0), 12, accent))
		panel.add_child(_make_label(String(data[3]), Vector2(14.0, 340.0), Vector2(268.0, 26.0), 10, Color("b7ccca"), HORIZONTAL_ALIGNMENT_CENTER))
		var abilities := _make_label(String(data[5]), Vector2(14.0, 378.0), Vector2(268.0, 52.0), 8, Color("81999b"), HORIZONTAL_ALIGNMENT_CENTER)
		abilities.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		panel.add_child(abilities)
		var button := _make_button(Vector2(46.0, 446.0), Vector2(204.0, 44.0), "BEGIN %s RUN" % String(data[1]), accent)
		button.mouse_entered.connect(func() -> void: _select(index))
		button.pressed.connect(func() -> void: _deploy(index))
		panel.add_child(button)
		_buttons.append(button)

	_fade = ColorRect.new()
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.color = Color(0.01, 0.015, 0.02, 0.0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_fade)


func _select(index: int) -> void:
	if _transitioning or index == _selected:
		return
	_selected = clampi(index, 0, HERO_SCENES.size() - 1)
	_refresh_selection()
	for device: int in Input.get_connected_joypads():
		Input.start_joy_vibration(device, 0.08, 0.14, 0.06)


func _deploy(index: int) -> void:
	if _transitioning:
		return
	_selected = clampi(index, 0, HERO_SCENES.size() - 1)
	_transitioning = true
	_transition_time = 0.0
	for device: int in Input.get_connected_joypads():
		Input.start_joy_vibration(device, 0.22, 0.38, 0.12)

func _refresh_selection() -> void:
	for index: int in _panels.size():
		var panel_style := _panels[index].get_theme_stylebox(&"panel") as StyleBoxFlat
		panel_style.set_border_width_all(3 if index == _selected else 1)
		panel_style.bg_color.a = 0.34 if index == _selected else 0.72
		_buttons[index].modulate = Color.WHITE if index == _selected else Color(0.70, 0.76, 0.78, 0.72)
		_heroes[index].modulate = Color.WHITE if index == _selected else Color(0.52, 0.60, 0.63, 0.60)
	queue_redraw()


func _draw() -> void:
	var center: Vector2 = HERO_CENTERS[_selected]
	var accent: Color = HERO_ACCENTS[_selected]
	var pulse := 0.82 + sin(Time.get_ticks_msec() * 0.005) * 0.08
	draw_arc(center, 92.0 * pulse, 0.0, TAU, 72, Color(accent, 0.52), 3.0, true)
	draw_arc(center, 112.0 * pulse, -0.72, 0.72, 32, Color(accent, 0.22), 7.0, true)


func _make_panel(at: Vector2, panel_size: Vector2, fill: Color, border: Color) -> Panel:
	var panel := Panel.new()
	panel.position = at
	panel.size = panel_size
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
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


func _make_button(at: Vector2, button_size: Vector2, text: String, accent: Color) -> Button:
	var button := Button.new()
	button.position = at
	button.size = button_size
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_override(&"font", _font)
	button.add_theme_font_size_override(&"font_size", 14)
	button.add_theme_color_override(&"font_color", Color("f7edd4"))
	button.add_theme_color_override(&"font_hover_color", Color.WHITE)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(accent, 0.16)
	normal.border_color = Color(accent, 0.86)
	normal.set_border_width_all(1)
	normal.corner_radius_top_left = 4
	normal.corner_radius_top_right = 4
	normal.corner_radius_bottom_left = 4
	normal.corner_radius_bottom_right = 4
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(accent, 0.34)
	hover.set_border_width_all(2)
	button.add_theme_stylebox_override(&"normal", normal)
	button.add_theme_stylebox_override(&"hover", hover)
	button.add_theme_stylebox_override(&"pressed", hover)
	return button