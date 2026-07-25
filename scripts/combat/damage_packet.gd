class_name DamagePacket
extends RefCounted


var source: Node
var health_damage: float = 0.0
var resolve_damage: float = 0.0
var knockback_force: float = 0.0
var hit_stop_seconds: float = 0.0
var camera_trauma: float = 0.0
var rumble_strength: float = 0.0
var tags: Array[StringName] = []
var survivor_ability_slot := StringName()
var survivor_power_applied := false


static func kat_primary(stage: int, owner: Node) -> DamagePacket:
	var packet := DamagePacket.new()
	var clamped_stage := clampi(stage, 0, 2)
	packet.source = owner
	packet.health_damage = [16.0, 21.0, 38.0][clamped_stage]
	packet.resolve_damage = [13.0, 18.0, 46.0][clamped_stage]
	packet.knockback_force = [170.0, 230.0, 470.0][clamped_stage]
	packet.hit_stop_seconds = [0.026, 0.033, 0.056][clamped_stage]
	packet.camera_trauma = [0.10, 0.16, 0.38][clamped_stage]
	packet.rumble_strength = [0.16, 0.23, 0.52][clamped_stage]
	packet.tags.assign([&"melee", &"primary"])
	if clamped_stage == 2:
		packet.tags.append(&"curse")
		packet.tags.append(&"heavy")
	return packet


static func kat_slam(power: float, owner: Node) -> DamagePacket:
	var shaped := CombatMath.shaped_charge(power)
	var packet := DamagePacket.new()
	packet.source = owner
	packet.health_damage = lerpf(34.0, 82.0, shaped)
	packet.resolve_damage = lerpf(48.0, 112.0, shaped)
	packet.knockback_force = lerpf(360.0, 780.0, shaped)
	packet.hit_stop_seconds = lerpf(0.052, 0.082, shaped)
	packet.camera_trauma = lerpf(0.34, 0.72, shaped)
	packet.rumble_strength = lerpf(0.46, 0.92, shaped)
	packet.tags.assign([&"heavy", &"signature", &"control", &"curse"])
	packet.survivor_ability_slot = &"signature"
	return packet


static func kat_march(owner: Node) -> DamagePacket:
	var packet := DamagePacket.new()
	packet.source = owner
	packet.health_damage = 20.0
	packet.resolve_damage = 38.0
	packet.knockback_force = 510.0
	packet.hit_stop_seconds = 0.038
	packet.camera_trauma = 0.24
	packet.rumble_strength = 0.32
	packet.tags.assign([&"melee", &"defense", &"curse"])
	packet.survivor_ability_slot = &"evade"
	return packet


static func kat_mote(owner: Node) -> DamagePacket:
	var packet := DamagePacket.new()
	packet.source = owner
	packet.health_damage = 9.0
	packet.resolve_damage = 4.0
	packet.knockback_force = 55.0
	packet.hit_stop_seconds = 0.018
	packet.camera_trauma = 0.05
	packet.rumble_strength = 0.06
	packet.tags.assign([&"summon", &"drain"])
	packet.survivor_ability_slot = &"ability_1"
	return packet


static func kat_halo(owner: Node) -> DamagePacket:
	var packet := DamagePacket.new()
	packet.source = owner
	packet.health_damage = 6.0
	packet.resolve_damage = 7.0
	packet.knockback_force = 20.0
	packet.hit_stop_seconds = 0.012
	packet.camera_trauma = 0.025
	packet.rumble_strength = 0.03
	packet.tags.assign([&"aura", &"drain", &"curse"])
	packet.survivor_ability_slot = &"ability_2"
	return packet


static func kat_communion(owner: Node, curse_stacks: int) -> DamagePacket:
	var packet := DamagePacket.new()
	packet.source = owner
	packet.health_damage = 42.0 + 11.0 * float(maxi(0, curse_stacks))
	packet.resolve_damage = 62.0 + 8.0 * float(maxi(0, curse_stacks))
	packet.knockback_force = 690.0
	packet.hit_stop_seconds = 0.092
	packet.camera_trauma = 0.94
	packet.rumble_strength = 1.0
	packet.tags.assign([&"ultimate", &"drain", &"curse", &"heavy"])
	packet.survivor_ability_slot = &"ultimate"
	return packet


static func sniff_dart(owner: Node, blessing_count: int, chain_depth := 0) -> DamagePacket:
	var stacks := clampi(blessing_count, 0, 10)
	var depth := maxi(0, chain_depth)
	var blessing_scale := 1.0 + float(stacks) * 0.085
	var chain_scale := pow(0.72, float(depth))
	var packet := DamagePacket.new()
	packet.source = owner
	packet.health_damage = 18.0 * blessing_scale * chain_scale
	packet.resolve_damage = 8.0 * blessing_scale * chain_scale
	packet.knockback_force = 115.0 * chain_scale
	packet.hit_stop_seconds = 0.024 if depth == 0 else 0.014
	packet.camera_trauma = 0.12 if depth == 0 else 0.055
	packet.rumble_strength = 0.14 if depth == 0 else 0.07
	packet.tags.assign([&"projectile", &"lightning", &"primary"])
	if depth > 0:
		packet.tags.append(&"chain")
	return packet


static func sniff_dash(owner: Node, charge: float, stacks_spent: int) -> DamagePacket:
	var shaped := CombatMath.shaped_charge(charge)
	var stack_scale := 1.0 + float(clampi(stacks_spent, 0, 3)) * 0.16
	var packet := DamagePacket.new()
	packet.source = owner
	packet.health_damage = lerpf(23.0, 47.0, shaped) * stack_scale
	packet.resolve_damage = lerpf(18.0, 44.0, shaped) * stack_scale
	packet.knockback_force = lerpf(240.0, 510.0, shaped)
	packet.hit_stop_seconds = lerpf(0.032, 0.052, shaped)
	packet.camera_trauma = lerpf(0.19, 0.42, shaped)
	packet.rumble_strength = lerpf(0.24, 0.58, shaped)
	packet.tags.assign([&"movement", &"lightning", &"signature", &"control"])
	packet.survivor_ability_slot = &"signature"
	return packet


static func sniff_flashstep(owner: Node, blessing_count: int) -> DamagePacket:
	var packet := DamagePacket.new()
	packet.source = owner
	packet.health_damage = 9.0 + float(clampi(blessing_count, 0, 10)) * 0.7
	packet.resolve_damage = 10.0
	packet.knockback_force = 135.0
	packet.hit_stop_seconds = 0.016
	packet.camera_trauma = 0.07
	packet.rumble_strength = 0.09
	packet.tags.assign([&"movement", &"lightning", &"evade"])
	packet.survivor_ability_slot = &"evade"
	return packet


static func sniff_surge(owner: Node, stacks_spent: int) -> DamagePacket:
	var stacks := clampi(stacks_spent, 0, 10)
	var packet := DamagePacket.new()
	packet.source = owner
	packet.health_damage = 31.0 + float(stacks) * 7.0
	packet.resolve_damage = 34.0 + float(stacks) * 4.5
	packet.knockback_force = 380.0 + float(stacks) * 27.0
	packet.hit_stop_seconds = lerpf(0.046, 0.078, float(stacks) / 10.0)
	packet.camera_trauma = lerpf(0.31, 0.74, float(stacks) / 10.0)
	packet.rumble_strength = lerpf(0.40, 0.90, float(stacks) / 10.0)
	packet.tags.assign([&"area", &"lightning", &"health_cost", &"heavy"])
	packet.survivor_ability_slot = &"ability_2"
	return packet


static func sniff_annihilation(owner: Node, blessing_count: int) -> DamagePacket:
	var stacks := clampi(blessing_count, 0, 10)
	var packet := DamagePacket.new()
	packet.source = owner
	packet.health_damage = 68.0 + float(stacks) * 9.0
	packet.resolve_damage = 82.0 + float(stacks) * 6.0
	packet.knockback_force = 760.0
	packet.hit_stop_seconds = 0.096
	packet.camera_trauma = 1.0
	packet.rumble_strength = 1.0
	packet.tags.assign([&"ultimate", &"lightning", &"health_cost", &"heavy"])
	packet.survivor_ability_slot = &"ultimate"
	return packet


static func nad_foresee(owner: Node, focus_stacks: int) -> DamagePacket:
	var focus := clampi(focus_stacks, 0, 5)
	var packet := DamagePacket.new()
	packet.source = owner
	packet.health_damage = 11.0 + 1.5 * float(focus)
	packet.resolve_damage = 17.0 + 2.0 * float(focus)
	packet.knockback_force = 62.0
	packet.hit_stop_seconds = 0.020
	packet.camera_trauma = 0.08
	packet.rumble_strength = 0.10
	packet.tags.assign([&"mental", &"primary", &"control"])
	return packet


static func nad_mantle(owner: Node, charge: float) -> DamagePacket:
	var shaped := CombatMath.shaped_charge(charge)
	var packet := DamagePacket.new()
	packet.source = owner
	packet.health_damage = lerpf(18.0, 36.0, shaped)
	packet.resolve_damage = lerpf(26.0, 54.0, shaped)
	packet.knockback_force = lerpf(90.0, 230.0, shaped)
	packet.hit_stop_seconds = lerpf(0.035, 0.060, shaped)
	packet.camera_trauma = lerpf(0.20, 0.48, shaped)
	packet.rumble_strength = lerpf(0.28, 0.68, shaped)
	packet.tags.assign([&"mental", &"signature", &"control", &"area"])
	packet.survivor_ability_slot = &"signature"
	return packet


static func nad_anchor(owner: Node) -> DamagePacket:
	var packet := DamagePacket.new()
	packet.source = owner
	packet.health_damage = 26.0
	packet.resolve_damage = 34.0
	packet.knockback_force = 280.0
	packet.hit_stop_seconds = 0.040
	packet.camera_trauma = 0.27
	packet.rumble_strength = 0.36
	packet.tags.assign([&"mental", &"anchor", &"control", &"area"])
	packet.survivor_ability_slot = &"ability_1"
	return packet


static func nad_cascade(owner: Node, focus_stacks: int) -> DamagePacket:
	var focus := clampi(focus_stacks, 0, 5)
	var packet := DamagePacket.new()
	packet.source = owner
	packet.health_damage = 24.0 + 4.0 * float(focus)
	packet.resolve_damage = 22.0 + 3.0 * float(focus)
	packet.knockback_force = 190.0
	packet.hit_stop_seconds = 0.038
	packet.camera_trauma = 0.24
	packet.rumble_strength = 0.31
	packet.tags.assign([&"mental", &"cascade", &"control", &"area"])
	packet.survivor_ability_slot = &"ability_2"
	return packet


static func nad_conduit(owner: Node, focus_stacks: int, was_locked: bool) -> DamagePacket:
	var focus := clampi(focus_stacks, 0, 5)
	var packet := DamagePacket.new()
	packet.source = owner
	packet.health_damage = (64.0 if was_locked else 34.0) + 8.0 * float(focus)
	packet.resolve_damage = (74.0 if was_locked else 42.0) + 5.0 * float(focus)
	packet.knockback_force = 460.0 if was_locked else 250.0
	packet.hit_stop_seconds = 0.086 if was_locked else 0.052
	packet.camera_trauma = 0.88 if was_locked else 0.48
	packet.rumble_strength = 1.0 if was_locked else 0.58
	packet.tags.assign([&"mental", &"ultimate", &"control", &"area"])
	packet.survivor_ability_slot = &"ultimate"
	return packet


static func fin_dagger(owner: Node, stage: int, damage_scale := 1.0) -> DamagePacket:
	var clamped_stage := clampi(stage, 0, 2)
	var packet := DamagePacket.new()
	packet.source = owner
	packet.health_damage = [13.0, 17.0, 29.0][clamped_stage] * maxf(0.0, damage_scale)
	packet.resolve_damage = [8.0, 11.0, 20.0][clamped_stage]
	packet.knockback_force = [72.0, 95.0, 185.0][clamped_stage]
	packet.hit_stop_seconds = [0.018, 0.024, 0.040][clamped_stage]
	packet.camera_trauma = [0.06, 0.09, 0.20][clamped_stage]
	packet.rumble_strength = [0.08, 0.12, 0.26][clamped_stage]
	packet.tags.assign([&"fin", &"pierce", &"melee", &"primary"])
	return packet


static func fin_mind_pierce(owner: Node, charge: float, marks: int, backstab: bool) -> DamagePacket:
	var shaped := CombatMath.shaped_charge(charge)
	var mark_count := clampi(marks, 0, 5)
	var packet := DamagePacket.new()
	packet.source = owner
	packet.health_damage = lerpf(34.0, 74.0, shaped) * (1.0 + 0.17 * float(mark_count)) * (1.32 if backstab else 1.0)
	packet.resolve_damage = lerpf(22.0, 54.0, shaped) + 5.0 * float(mark_count)
	packet.knockback_force = lerpf(170.0, 390.0, shaped)
	packet.hit_stop_seconds = lerpf(0.036, 0.070, shaped)
	packet.camera_trauma = lerpf(0.22, 0.58, shaped)
	packet.rumble_strength = lerpf(0.30, 0.78, shaped)
	packet.tags.assign([&"fin", &"pierce", &"signature", &"exploit"])
	packet.survivor_ability_slot = &"signature"
	return packet


static func fin_arrow(owner: Node, charge: float, range_ratio: float) -> DamagePacket:
	var shaped := CombatMath.shaped_charge(charge)
	var distance_bonus := lerpf(1.0, 1.36, clampf(range_ratio, 0.0, 1.0))
	var packet := DamagePacket.new()
	packet.source = owner
	packet.health_damage = lerpf(21.0, 65.0, shaped) * distance_bonus
	packet.resolve_damage = lerpf(11.0, 31.0, shaped)
	packet.knockback_force = lerpf(95.0, 260.0, shaped)
	packet.hit_stop_seconds = lerpf(0.020, 0.046, shaped)
	packet.camera_trauma = lerpf(0.08, 0.28, shaped)
	packet.rumble_strength = lerpf(0.10, 0.36, shaped)
	packet.tags.assign([&"fin", &"pierce", &"projectile", &"bow"])
	return packet


static func fin_throwing_dagger(owner: Node) -> DamagePacket:
	var packet := DamagePacket.new()
	packet.source = owner
	packet.health_damage = 17.0
	packet.resolve_damage = 8.0
	packet.knockback_force = 78.0
	packet.hit_stop_seconds = 0.018
	packet.camera_trauma = 0.07
	packet.rumble_strength = 0.08
	packet.tags.assign([&"fin", &"pierce", &"projectile", &"utility"])
	packet.survivor_ability_slot = &"ability_2"
	return packet


static func fin_crossbow(owner: Node, charge: float, marks: int) -> DamagePacket:
	var shaped := CombatMath.shaped_charge(charge)
	var mark_count := clampi(marks, 0, 5)
	var packet := DamagePacket.new()
	packet.source = owner
	packet.health_damage = lerpf(82.0, 168.0, shaped) * (1.0 + 0.12 * float(mark_count))
	packet.resolve_damage = lerpf(68.0, 142.0, shaped) + 7.0 * float(mark_count)
	packet.knockback_force = lerpf(520.0, 880.0, shaped)
	packet.hit_stop_seconds = lerpf(0.066, 0.104, shaped)
	packet.camera_trauma = lerpf(0.58, 1.0, shaped)
	packet.rumble_strength = lerpf(0.72, 1.0, shaped)
	packet.tags.assign([&"fin", &"pierce", &"crossbow", &"heavy", &"exploit"])
	return packet


static func fin_rod(owner: Node, current_resolve: float) -> DamagePacket:
	var packet := DamagePacket.new()
	packet.source = owner
	packet.health_damage = 14.0
	packet.resolve_damage = 13.0 + maxf(0.0, current_resolve) * 0.20
	packet.knockback_force = 68.0
	packet.hit_stop_seconds = 0.020
	packet.camera_trauma = 0.09
	packet.rumble_strength = 0.11
	packet.tags.assign([&"fin", &"object", &"rod", &"projectile"])
	return packet


static func fin_mutivarg(owner: Node, power: float) -> DamagePacket:
	var packet := DamagePacket.new()
	packet.source = owner
	packet.health_damage = lerpf(8.0, 15.0, clampf(power, 0.0, 1.0))
	packet.resolve_damage = lerpf(15.0, 29.0, clampf(power, 0.0, 1.0))
	packet.knockback_force = 42.0
	packet.hit_stop_seconds = 0.016
	packet.camera_trauma = 0.06
	packet.rumble_strength = 0.08
	packet.tags.assign([&"fin", &"object", &"mutivarg", &"control", &"area"])
	packet.survivor_ability_slot = &"signature"
	return packet


static func fin_alchemical(owner: Node) -> DamagePacket:
	var packet := DamagePacket.new()
	packet.source = owner
	packet.health_damage = 11.0
	packet.resolve_damage = 13.0
	packet.knockback_force = 34.0
	packet.hit_stop_seconds = 0.014
	packet.camera_trauma = 0.05
	packet.rumble_strength = 0.06
	packet.tags.assign([&"fin", &"object", &"alchemical", &"area"])
	return packet


static func enemy_melee(owner: Node, damage := 24.0) -> DamagePacket:
	var packet := DamagePacket.new()
	packet.source = owner
	packet.health_damage = damage
	packet.resolve_damage = damage * 0.65
	packet.knockback_force = 320.0
	packet.hit_stop_seconds = 0.032
	packet.camera_trauma = 0.19
	packet.rumble_strength = 0.28
	packet.tags.assign([&"enemy", &"melee"])
	return packet


static func heavy_slam(charge: float) -> DamagePacket:
	var shaped := CombatMath.shaped_charge(charge)
	var packet := DamagePacket.new()
	packet.health_damage = lerpf(26.0, 64.0, shaped)
	packet.resolve_damage = lerpf(34.0, 82.0, shaped)
	packet.knockback_force = lerpf(260.0, 620.0, shaped)
	packet.hit_stop_seconds = lerpf(0.045, 0.072, shaped)
	packet.camera_trauma = lerpf(0.28, 0.58, shaped)
	packet.rumble_strength = lerpf(0.35, 0.82, shaped)
	packet.tags.assign([&"heavy", &"signature", &"control"])
	return packet