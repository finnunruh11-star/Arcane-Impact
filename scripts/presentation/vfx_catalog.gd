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
const KAT_SLASHES: Array[Texture2D] = [
	preload("res://assets/vfx/pixel_crawler/kat_slash_1.png"),
	preload("res://assets/vfx/pixel_crawler/kat_slash_2.png"),
	preload("res://assets/vfx/pixel_crawler/kat_slash_3.png"),
]
const FIN_SLASHES: Array[Texture2D] = [
	preload("res://assets/vfx/pixel_crawler/fin_slash_1.png"),
	preload("res://assets/vfx/pixel_crawler/fin_slash_2.png"),
	preload("res://assets/vfx/pixel_crawler/fin_slash_3.png"),
]
const DIRECTIONAL_IMPACT: Texture2D = preload("res://assets/vfx/pixel_crawler/directional_impact.png")
const WARLOCK_BLOOM: Texture2D = preload("res://assets/vfx/pixel_crawler/warlock_bloom.png")
const WARLOCK_WAVE: Texture2D = preload("res://assets/vfx/pixel_crawler/warlock_wave.png")
const WARLOCK_ORB: Texture2D = preload("res://assets/vfx/pixel_crawler/warlock_orb.png")


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
		&"kat_slash_1":
			effect.configure(KAT_SLASHES[0], Vector2i(128, 128), 20.0, loop)
		&"kat_slash_2":
			effect.configure(KAT_SLASHES[1], Vector2i(128, 128), 20.0, loop)
		&"kat_slash_3":
			effect.configure(KAT_SLASHES[2], Vector2i(128, 128), 20.0, loop)
		&"fin_slash_1":
			effect.configure(FIN_SLASHES[0], Vector2i(128, 128), 22.0, loop)
		&"fin_slash_2":
			effect.configure(FIN_SLASHES[1], Vector2i(128, 128), 22.0, loop)
		&"fin_slash_3":
			effect.configure(FIN_SLASHES[2], Vector2i(128, 128), 22.0, loop)
		&"fin_cut", &"fin_shot":
			effect.configure(DIRECTIONAL_IMPACT, Vector2i(128, 64), 20.0, loop)
		&"fin_shadow", &"fin_step":
			effect.configure(SNIFF_DASH, Vector2i(96, 96), 15.0, loop)
		&"fin_tool":
			effect.configure(SNIFF_SURGE, Vector2i(96, 96), 15.0, loop)
		&"fin_smoke":
			effect.configure(KAT_ABSORB, Vector2i(128, 128), 15.0, loop)
		&"fin_switch":
			effect.configure(SNIFF_BLESSING, Vector2i(64, 64), 15.0, loop)
		&"nad_warlock_orb":
			effect.configure(WARLOCK_ORB, Vector2i(128, 128), 15.0, loop)
		&"nad_warlock_wave":
			effect.configure(WARLOCK_WAVE, Vector2i(192, 128), 18.0, loop)
		&"nad_warlock_bloom":
			effect.configure(WARLOCK_BLOOM, Vector2i(128, 128), 15.0, loop)
		_:
			push_error("Unknown VFX catalog entry: %s" % effect_id)
	return effect


static func _rotation_for(effect_id: StringName, direction: Vector2) -> float:
	if effect_id == &"kat_impact" and not direction.is_zero_approx():
		return direction.angle() + PI * 0.5
	if effect_id in [&"fin_cut", &"fin_shot"] and not direction.is_zero_approx():
		return direction.angle() + PI
	if effect_id in [&"kat_slash_1", &"kat_slash_2", &"kat_slash_3", &"fin_slash_1", &"fin_slash_2", &"fin_slash_3", &"nad_warlock_wave"] and not direction.is_zero_approx():
		return direction.angle()
	return 0.0