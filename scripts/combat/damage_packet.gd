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