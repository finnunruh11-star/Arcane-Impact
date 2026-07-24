class_name VfxCatalog
extends RefCounted


const KAT_ABSORB: Texture2D = preload("res://assets/vfx/kat/absorb_violet.png")
const KAT_HEAL: Texture2D = preload("res://assets/vfx/kat/heal_red.png")
const KAT_CURSE: Texture2D = preload("res://assets/vfx/kat/curse_death_red.png")
const KAT_IMPACT: Texture2D = preload("res://assets/vfx/kat/directional_impact_yellow.png")
const KAT_COMMUNION: Texture2D = preload("res://assets/vfx/kat/black_communion_explosion.png")
const SNIFF_STRIKE: Texture2D = preload("res://assets/vfx/sniff/lightning_strike_violet.png")
const SNIFF_BLESSING: Texture2D = preload("res://assets/vfx/sniff/blessing_sparkle_blue.png")
const SNIFF_ANNIHILATION: Texture2D = preload("res://assets/vfx/sniff/annihilation_light_yellow.png")
const SNIFF_SURGE: Texture2D = preload("res://assets/vfx/sniff/surge_impact_yellow.png")
const SNIFF_DASH: Texture2D = preload("res://assets/vfx/sniff/dash_burst_violet.png")


static func spawn_world(
	parent: Node,
	effect_id: StringName,
	at: Vector2,
	direction := Vector2.RIGHT,
	size_scale := 1.0,
	tint := Color.WHITE
) -> PixelSheetEffect:
	var effect := _build(effect_id, false)
	parent.add_child(effect)
	effect.global_position = at
	effect.rotation = _rotation_for(effect_id, direction)
	effect.scale = Vector2.ONE * size_scale
	effect.modulate = tint
	return effect


static func spawn_attached(
	parent: Node2D,
	effect_id: StringName,
	local_position := Vector2.ZERO,
	size_scale := 1.0,
	tint := Color.WHITE,
	loop := true
) -> PixelSheetEffect:
	var effect := _build(effect_id, loop)
	parent.add_child(effect)
	effect.position = local_position
	effect.scale = Vector2.ONE * size_scale
	effect.modulate = tint
	return effect


static func _build(effect_id: StringName, loop: bool) -> PixelSheetEffect:
	var effect := PixelSheetEffect.new()
	match effect_id:
		&"kat_absorb":
			if loop:
				effect.configure(KAT_ABSORB, Vector2i(128, 128), 15.0, true, 4, 25)
			else:
				effect.configure(KAT_ABSORB, Vector2i(128, 128), 15.0, false)
		&"kat_heal":
			effect.configure(KAT_HEAL, Vector2i(128, 128), 15.0, loop)
		&"kat_curse":
			effect.configure(KAT_CURSE, Vector2i(64, 64), 15.0, loop)
		&"kat_impact":
			effect.configure(KAT_IMPACT, Vector2i(80, 80), 15.0, loop)
		&"kat_communion":
			effect.configure(KAT_COMMUNION, Vector2i(192, 192), 15.0, loop)
		&"sniff_strike":
			effect.configure(SNIFF_STRIKE, Vector2i(128, 128), 15.0, loop)
		&"sniff_blessing":
			if loop:
				effect.configure(SNIFF_BLESSING, Vector2i(64, 64), 15.0, true, 1, 11)
			else:
				effect.configure(SNIFF_BLESSING, Vector2i(64, 64), 15.0, false)
		&"sniff_annihilation":
			effect.configure(SNIFF_ANNIHILATION, Vector2i(256, 144), 15.0, loop)
		&"sniff_surge":
			effect.configure(SNIFF_SURGE, Vector2i(96, 96), 15.0, loop)
		&"sniff_dash":
			effect.configure(SNIFF_DASH, Vector2i(96, 96), 15.0, loop)
		&"fin_cut", &"fin_shot":
			effect.configure(KAT_IMPACT, Vector2i(80, 80), 15.0, loop)
		&"fin_shadow":
			effect.configure(SNIFF_DASH, Vector2i(96, 96), 15.0, loop)
		&"fin_tool":
			effect.configure(SNIFF_SURGE, Vector2i(96, 96), 15.0, loop)
		&"fin_smoke", &"fin_parry":
			effect.configure(KAT_ABSORB, Vector2i(128, 128), 15.0, loop)
		&"fin_switch":
			effect.configure(SNIFF_BLESSING, Vector2i(64, 64), 15.0, loop)
		_:
			push_error("Unknown VFX catalog entry: %s" % effect_id)
	return effect


static func _rotation_for(effect_id: StringName, direction: Vector2) -> float:
	if effect_id in [&"kat_impact", &"fin_cut", &"fin_shot"] and not direction.is_zero_approx():
		return direction.angle() + PI * 0.5
	return 0.0