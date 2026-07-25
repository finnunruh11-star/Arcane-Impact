extends SceneTree


const InputProfileScript := preload("res://scripts/core/input_profile.gd")
const CombatMathScript := preload("res://scripts/combat/combat_math.gd")
const DamagePacketScript := preload("res://scripts/combat/damage_packet.gd")
const DamageResolverScript := preload("res://scripts/combat/damage_resolver.gd")
const PrototypePlayerScript := preload("res://scripts/actors/prototype_player.gd")
const TargetDummyScript := preload("res://scripts/actors/target_dummy.gd")
const KatPlayerScript := preload("res://scripts/characters/kat/kat_player.gd")
const SniffPlayerScript := preload("res://scripts/characters/sniff/sniff_player.gd")
const SniffDartScript := preload("res://scripts/characters/sniff/lightning_dart.gd")
const NadPlayerScript := preload("res://scripts/characters/nad/nad_player.gd")
const FinPlayerScript := preload("res://scripts/characters/fin/fin_player.gd")
const FinProjectileScript := preload("res://scripts/characters/fin/fin_projectile.gd")
const FinFieldScript := preload("res://scripts/characters/fin/fin_field.gd")
const ReliquaryPursuerScript := preload("res://scripts/enemies/reliquary_pursuer.gd")
const VfxCatalogScript := preload("res://scripts/presentation/vfx_catalog.gd")

var _failures: Array[String] = []
var _check_count := 0


func _init() -> void:
	call_deferred(&"_run")


func _run() -> void:
	InputProfileScript.ensure_default_bindings()
	_expect(InputProfileScript.has_complete_action_set(), "default input action coverage")
	_expect(
		InputMap.action_get_events(&"signature").size() == 2,
		"signature has mouse and controller bindings"
	)

	_expect(is_equal_approx(CombatMathScript.normalized_charge(0.45, 0.9), 0.5), "charge normalization")
	_expect(CombatMathScript.normalized_charge(2.0, 0.9) == 1.0, "charge clamps high")
	_expect(CombatMathScript.apply_radial_deadzone(Vector2(0.1, 0.0), 0.18).is_zero_approx(), "radial deadzone")
	_expect(
		CombatMathScript.oriented_box_contains(Vector2.ZERO, Vector2.RIGHT, Vector2(80.0, 20.0), 120.0, 40.0),
		"oriented attack box accepts an interior point"
	)
	_expect(
		not CombatMathScript.oriented_box_contains(Vector2.ZERO, Vector2.RIGHT, Vector2(80.0, 60.0), 120.0, 40.0),
		"oriented attack box rejects a wide point"
	)

	var light_packet = DamagePacketScript.heavy_slam(0.0)
	var full_packet = DamagePacketScript.heavy_slam(1.0)
	_expect(full_packet.health_damage > light_packet.health_damage, "charge increases health damage")
	_expect(full_packet.resolve_damage > light_packet.resolve_damage, "charge increases Resolve damage")
	_expect(full_packet.hit_stop_seconds <= 0.075, "heavy hit-stop remains inside its budget")
	var finisher_packet = DamagePacketScript.kat_primary(2, null)
	_expect(finisher_packet.tags.has(&"curse"), "Kat finisher carries its curse contract")
	_expect(finisher_packet.health_damage > DamagePacketScript.kat_primary(0, null).health_damage, "Kat combo finisher escalates damage")
	_expect(DamagePacketScript.kat_communion(null, 3).health_damage > DamagePacketScript.kat_communion(null, 0).health_damage, "communion scales with curse stacks")
	_expect(TargetDummyScript.MAX_RESOLVE > full_packet.resolve_damage, "one heavy cast does not instantly break full Resolve")

	var dummy = TargetDummyScript.new()
	dummy.position = Vector2(640.0, 360.0)
	root.add_child(dummy)
	await process_frame
	var applied: bool = DamageResolverScript.apply(dummy, full_packet, Vector2.RIGHT)
	_expect(applied, "central damage resolver accepts a valid target")
	_expect(dummy.health < TargetDummyScript.MAX_HEALTH, "damage packet reduces target health")
	_expect(dummy.resolve < TargetDummyScript.MAX_RESOLVE, "damage packet reduces target Resolve")
	DamageResolverScript.apply(dummy, full_packet, Vector2.RIGHT)
	_expect(dummy.is_resolve_broken, "repeated control damage breaks Resolve")
	dummy.reset_full()
	_expect(dummy.health == TargetDummyScript.MAX_HEALTH and dummy.resolve == TargetDummyScript.MAX_RESOLVE, "dummy reset restores combat resources")
	var survivor_source = KatPlayerScript.new()
	survivor_source.set_survivor_power_multiplier(1.5)
	var survivor_packet = DamagePacketScript.kat_primary(0, survivor_source)
	DamageResolverScript.apply(dummy, survivor_packet, Vector2.RIGHT)
	_expect(is_equal_approx(TargetDummyScript.MAX_HEALTH - dummy.health, 24.0), "Survivors power scales outgoing health damage")
	dummy.reset_full()
	DamageResolverScript.apply(dummy, survivor_packet, Vector2.RIGHT)
	_expect(is_equal_approx(TargetDummyScript.MAX_HEALTH - dummy.health, 24.0), "reused packets do not compound Survivors power")
	dummy.reset_full()
	survivor_source.set_survivor_mode(true)
	survivor_source.set_survivor_power_multiplier(1.0)
	survivor_source.set_survivor_ability_progress(&"signature", 1, 1, 0.58, 1.32)
	var tiered_packet = DamagePacketScript.kat_slam(0.0, survivor_source)
	DamageResolverScript.apply(dummy, tiered_packet, Vector2.RIGHT)
	_expect(is_equal_approx(TargetDummyScript.MAX_HEALTH - dummy.health, 34.0 * 0.58), "ability tier and rank power scales only its tagged damage")
	dummy.reset_full()
	survivor_source.set_survivor_power_multiplier(1.12)
	survivor_source.set_survivor_ability_progress(&"signature", 2, 3, 1.12, 0.94)
	survivor_source.set_survivor_power_multiplier(1.0)
	survivor_source.apply_survivor_stat(&"strength", 1)
	var compounded_packet = DamagePacketScript.kat_slam(0.0, survivor_source)
	DamageResolverScript.apply(dummy, compounded_packet, Vector2.RIGHT)
	_expect(is_equal_approx(TargetDummyScript.MAX_HEALTH - dummy.health, 34.0 * 1.12 * 1.12), "Strength and slot-specific ability power multiply once each")
	_expect(DamagePacketScript.kat_primary(0, survivor_source).survivor_scaling == &"strength", "swords and heavy weapons use Strength scaling")
	_expect(DamagePacketScript.fin_dagger(survivor_source, 0).survivor_scaling == &"dexterity", "daggers and bows use Dexterity scaling")
	_expect(DamagePacketScript.sniff_dart(survivor_source, 0).survivor_scaling == &"intelligence", "lightning and other spells use Intelligence scaling")
	var critical_source = KatPlayerScript.new()
	critical_source.apply_survivor_stat(&"luck", 20)
	seed(1337)
	var critical_damage := 0.0
	var critical_packet: DamagePacket
	for _attempt: int in 12:
		dummy.reset_full()
		var candidate := DamagePacketScript.kat_primary(0, critical_source)
		DamageResolverScript.apply(dummy, candidate, Vector2.RIGHT)
		if candidate.survivor_critical:
			critical_packet = candidate
			critical_damage = TargetDummyScript.MAX_HEALTH - dummy.health
			break
	_expect(is_instance_valid(critical_packet) and critical_packet.tags.has(&"critical"), "Luck can mark a resolved packet as critical")
	_expect(is_equal_approx(critical_damage, 16.0 * 3.5), "Luck increases critical damage and applies it once")
	critical_source.free()
	survivor_source.free()
	dummy.queue_free()
	await process_frame

	var combat_world := Node2D.new()
	root.add_child(combat_world)
	var attacker = PrototypePlayerScript.new()
	var overlap_dummy = TargetDummyScript.new()
	attacker.position = Vector2(430.0, 360.0)
	overlap_dummy.position = Vector2(590.0, 360.0)
	combat_world.add_child(attacker)
	combat_world.add_child(overlap_dummy)
	attacker.set("_using_gamepad", true)
	attacker.aim_direction = Vector2.RIGHT
	attacker.call("_begin_active")
	for _frame: int in 3:
		await physics_frame
		await process_frame
	_expect(overlap_dummy.health < TargetDummyScript.MAX_HEALTH, "live Area2D hitbox damages an overlapping target")
	var health_after_first_overlap: float = overlap_dummy.health
	attacker.call("_apply_attack_hits")
	_expect(overlap_dummy.health == health_after_first_overlap, "one activation cannot damage the same target twice")
	combat_world.queue_free()
	await process_frame

	var kat_world := Node2D.new()
	root.add_child(kat_world)
	var kat = KatPlayerScript.new()
	kat.position = Vector2(430.0, 360.0)
	kat_world.add_child(kat)
	var enemy = ReliquaryPursuerScript.new()
	enemy.configure(kat, 0)
	enemy.position = Vector2(570.0, 360.0)
	kat_world.add_child(enemy)
	await process_frame
	var role_enemies: Array[ReliquaryPursuer] = []
	var role_names: Dictionary = {}
	var attack_styles: Dictionary = {}
	var all_roles_have_sprites := true
	for role_index: int in ReliquaryPursuer.ROLE_COUNT:
		var role_enemy := ReliquaryPursuerScript.new() as ReliquaryPursuer
		role_enemy.configure(kat, role_index)
		role_enemy.position = Vector2(900.0 + float(role_index) * 80.0, 700.0)
		kat_world.add_child(role_enemy)
		role_enemies.append(role_enemy)
		role_names[role_enemy.display_name] = true
		attack_styles[role_enemy.get_attack_style()] = true
	await process_frame
	for role_enemy: ReliquaryPursuer in role_enemies:
		role_enemy.process_mode = Node.PROCESS_MODE_DISABLED
		all_roles_have_sprites = all_roles_have_sprites and role_enemy.get_node_or_null(^"EnemySprite") is AnimatedSprite2D
	_expect(role_names.size() == ReliquaryPursuer.ROLE_COUNT and attack_styles.size() == ReliquaryPursuer.ROLE_COUNT, "the horde exposes six named enemies with six distinct attack styles")
	_expect(all_roles_have_sprites, "every enemy role renders an imported animated mob sprite")
	_expect(role_enemies[ReliquaryPursuer.Role.BULWARK].max_health > role_enemies[ReliquaryPursuer.Role.RAIDER].max_health * 2.0 and role_enemies[ReliquaryPursuer.Role.BULWARK].move_speed < role_enemies[ReliquaryPursuer.Role.RAIDER].move_speed, "Iron Bulwarks are visibly tanky and slow")
	_expect(role_enemies[ReliquaryPursuer.Role.BLOODRUNNER].move_speed > role_enemies[ReliquaryPursuer.Role.RAIDER].move_speed, "Bloodrunners are the dedicated rushdown profile")
	role_enemies[ReliquaryPursuer.Role.RAIDER].global_position = Vector2(900.0, 700.0)
	role_enemies[ReliquaryPursuer.Role.BLOODRUNNER].global_position = Vector2(930.0, 700.0)
	_expect(not (role_enemies[ReliquaryPursuer.Role.RAIDER].call("_get_horde_separation_direction") as Vector2).is_zero_approx(), "nearby horde members steer apart instead of drawing directly on top of each other")
	var support_target := role_enemies[ReliquaryPursuer.Role.RAIDER]
	var warcaller := role_enemies[ReliquaryPursuer.Role.WARCALLER]
	support_target.global_position = Vector2(900.0, 700.0)
	warcaller.global_position = Vector2(980.0, 700.0)
	support_target.health = support_target.max_health * 0.40
	var support_health_before: float = support_target.health
	warcaller.call("_perform_support_pulse")
	_expect(support_target.health > support_health_before, "Warcaller support pulses heal nearby horde allies")
	var arcanist := role_enemies[ReliquaryPursuer.Role.BONE_ARCANIST]
	arcanist.global_position = kat.global_position + Vector2(-240.0, 0.0)
	arcanist.set("_facing", Vector2.RIGHT)
	var ranged_health_before: float = kat.health
	arcanist.call("_spawn_projectile", EnemyProjectile.Kind.ARCANE_ORB)
	var spawned_enemy_projectile := false
	for child: Node in kat_world.get_children():
		if child is EnemyProjectile:
			spawned_enemy_projectile = true
	_expect(spawned_enemy_projectile, "ranged enemy roles create collision-backed projectiles")
	for _frame: int in 90:
		await physics_frame
		await process_frame
		if kat.health < ranged_health_before:
			break
	_expect(kat.health < ranged_health_before, "Bone Arcanist projectiles travel into and damage the hero hurtbox")

	kat.aim_direction = Vector2.RIGHT
	kat.call("_begin_guard")
	var health_before_guard: float = kat.health
	var vitality_before_guard: float = kat.vitality
	var enemy_packet = DamagePacketScript.enemy_melee(enemy, 30.0)
	kat.receive_hit(enemy_packet, Vector2.LEFT)
	_expect(kat.health == health_before_guard, "Kat perfect guard negates frontal health damage")
	_expect(kat.vitality > vitality_before_guard, "Kat guard converts pressure into Vitality")
	_expect(enemy.get_curse_stacks() == 2, "Kat perfect guard reflects two curse stacks")
	kat.receive_hit(enemy_packet, Vector2.RIGHT)
	_expect(kat.health < health_before_guard, "Kat guard does not block attacks from behind")

	kat.call("_cast_leech_choir")
	_expect(kat.get_mote_count() == 3 and kat.is_leech_choir_active(), "Leech Choir toggles on with its full tier-three swarm")
	var choir_mana_before: float = kat.mana
	kat.call("_tick_sustained_mana", 1.0)
	_expect(kat.mana < choir_mana_before, "Leech Choir drains Mana centrally while active")
	kat.call("_cast_leech_choir")
	_expect(kat.get_mote_count() == 0 and not kat.is_leech_choir_active(), "Leech Choir toggles off even while its activation cooldown remains")
	kat.call("_cast_mourning_halo")
	_expect(kat.is_halo_active(), "Mourning Halo creates its collision-backed aura")
	var halo_mana_before: float = kat.mana
	kat.call("_tick_sustained_mana", 1.0)
	_expect(kat.mana < halo_mana_before, "Mourning Halo persists by draining substantial Mana")
	kat.call("_cast_mourning_halo")
	_expect(not kat.is_halo_active(), "Mourning Halo toggles off on a second cast")
	kat.call("_cast_mourning_halo")
	kat.mana = 0.1
	kat.call("_tick_sustained_mana", 1.0)
	_expect(kat.mana == 0.0 and not kat.is_halo_active(), "Kat's sustained spells shut off automatically when Mana is exhausted")
	kat.restore_mana(999.0)
	kat.apply_survivor_stat(&"mana", 24)
	kat.mana = 60.0
	kat.call("_cast_leech_choir")
	kat.call("_cast_mourning_halo")
	var neutral_sustain_before: float = kat.mana
	kat.call("_tick_sustained_mana", 1.0)
	_expect(kat.mana >= neutral_sustain_before and kat.is_leech_choir_active() and kat.is_halo_active(), "Mana regeneration can fully offset both of Kat's active channel drains")
	kat.call("_cast_leech_choir")
	kat.call("_cast_mourning_halo")
	kat.restore_mana(999.0)
	kat.call("_cast_mourning_halo")
	enemy.apply_curse(10, 6.0)
	_expect(enemy.get_curse_stacks() == 5, "enemy curse intensity caps at five stacks")
	var enemy_health_before_ultimate: float = enemy.health
	kat.vitality = KatPlayerScript.MAX_VITALITY
	var communion_mana_before: float = kat.mana
	kat.call("_begin_black_communion")
	_expect(is_equal_approx(kat.mana, communion_mana_before - KatPlayerScript.COMMUNION_MANA_COST), "Black Communion spends Mana while Kat's physical weapons remain free")
	kat.call("_resolve_black_communion")
	_expect(kat.vitality == 0.0, "Black Communion spends all Vitality")
	_expect(enemy.health < enemy_health_before_ultimate, "Black Communion damages cursed enemies")
	_expect(kat.ward > 0.0, "Black Communion converts its drain into ward")

	var impact_effect = VfxCatalogScript.spawn_world(root, &"kat_impact", Vector2.ZERO)
	_expect(impact_effect.hframes == 5 and impact_effect.vframes == 1, "licensed directional impact slices into five authored frames")
	impact_effect.queue_free()
	var sniff_effect_specs := {
		&"sniff_strike": 7,
		&"sniff_blessing": 14,
		&"sniff_annihilation": 9,
		&"sniff_surge": 7,
		&"sniff_dash": 10,
	}
	for effect_id: StringName in sniff_effect_specs:
		var sniff_effect = VfxCatalogScript.spawn_world(root, effect_id, Vector2.ZERO)
		_expect(sniff_effect.hframes == int(sniff_effect_specs[effect_id]) and sniff_effect.vframes == 1, "%s slices into its authored frames" % effect_id)
		sniff_effect.queue_free()
	var fin_effect_specs := {
		&"fin_cut": 5,
		&"fin_shot": 5,
		&"fin_shadow": 10,
		&"fin_tool": 7,
		&"fin_smoke": 31,
		&"fin_step": 10,
		&"fin_switch": 14,
	}
	for effect_id: StringName in fin_effect_specs:
		var fin_effect = VfxCatalogScript.spawn_world(root, effect_id, Vector2.ZERO)
		_expect(fin_effect.hframes == int(fin_effect_specs[effect_id]) and fin_effect.vframes == 1, "%s slices into its authored frames" % effect_id)
		fin_effect.queue_free()
	kat_world.queue_free()
	await process_frame

	var sniff_world := Node2D.new()
	root.add_child(sniff_world)
	var sniff = SniffPlayerScript.new()
	sniff.position = Vector2(430.0, 360.0)
	sniff_world.add_child(sniff)
	var sniff_enemies: Array[ReliquaryPursuer] = []
	for enemy_index: int in 3:
		var sniff_enemy := ReliquaryPursuerScript.new()
		sniff_enemy.configure(sniff, 1)
		sniff_enemy.position = Vector2(550.0 + float(enemy_index) * 120.0, 360.0)
		sniff_enemy.move_speed = 0.0
		sniff_world.add_child(sniff_enemy)
		sniff_enemies.append(sniff_enemy)
	await process_frame

	sniff.chain_chance = 1.0
	var primary_health_before: float = sniff_enemies[0].health
	var chain_health_before: float = sniff_enemies[1].health
	var second_chain_health_before: float = sniff_enemies[2].health
	sniff.on_lightning_dart_hit(sniff_enemies[0], sniff_enemies[0].global_position, Vector2.RIGHT, 0)
	_expect(sniff_enemies[0].health < primary_health_before, "Lightning Dart damages its primary target")
	_expect(sniff_enemies[1].health < chain_health_before, "Lightning Dart chains to a nearby second target")
	_expect(sniff_enemies[2].health < second_chain_health_before, "tier-three Lightning Dart evolves into a second damaging chain")
	_expect(sniff.get_blessing_count() == 3, "dart and both evolved chain hits each build Blessing")

	sniff.aim_direction = Vector2.RIGHT
	var dart_mana_before: float = sniff.mana
	sniff.call("_begin_dart")
	_expect(is_equal_approx(sniff.mana, dart_mana_before - SniffPlayerScript.DART_MANA_COST), "Lightning Dart spends Mana")
	sniff.call("_spawn_dart")
	var spawned_projectile := false
	for child: Node in sniff_world.get_children():
		if child.get_script() == SniffDartScript:
			spawned_projectile = true
			break
	_expect(spawned_projectile, "Lightning Dart spawns a collision-backed projectile")
	for _frame: int in 8:
		await physics_frame
		await process_frame

	var wager_health_before: float = sniff.health
	var wager_blessing_before: int = sniff.blessing
	sniff.call("_cast_roaring_blessing")
	_expect(sniff.health < wager_health_before, "Roaring Blessing visibly wagers health")
	_expect(sniff.blessing == mini(SniffPlayerScript.MAX_BLESSING, wager_blessing_before + 4), "Roaring Blessing grants four stacks")

	sniff.blessing = 5
	var surge_health_before: float = sniff.health
	var surge_target_before: float = sniff_enemies[0].health
	sniff.call("_begin_explosive_surge")
	for _frame: int in 3:
		await physics_frame
		await process_frame
	sniff.call("_resolve_explosive_surge")
	_expect(sniff.blessing == 0, "Explosive Surge cashes out all Blessing")
	_expect(sniff.health < surge_health_before, "Explosive Surge pays its health cost")
	_expect(sniff_enemies[0].health < surge_target_before, "Explosive Surge uses its collision radius to damage nearby enemies")

	sniff.global_position = Vector2(430.0, 500.0)
	sniff_enemies[2].global_position = Vector2(625.0, 500.0)
	sniff.blessing = 3
	sniff.aim_direction = Vector2.RIGHT
	var dash_target_before: float = sniff_enemies[2].health
	var dash_start_x: float = sniff.global_position.x
	sniff.call("_begin_thunder_dash")
	sniff.set("_dash_charge", 1.0)
	sniff.call("_release_thunder_dash")
	for _frame: int in 22:
		await physics_frame
		await process_frame
	_expect(sniff.global_position.x > dash_start_x + 300.0, "charged Thunder Dash traverses its authored distance")
	_expect(sniff_enemies[2].health < dash_target_before, "Thunder Dash damages an enemy crossed once")
	sniff.call("_begin_flashstep")
	_expect(
		is_equal_approx(sniff.flashstep_cooldown, SniffPlayerScript.FLASHSTEP_COOLDOWN) and sniff.flashstep_cooldown < 1.0,
		"Flashstep now has a much shorter reusable cooldown"
	)
	sniff.set("_state", SniffPlayerScript.State.FREE)
	sniff.set("_invulnerable_time", 0.0)
	sniff.call("_set_enemy_phasing", false)
	(sniff.get("_attack_area") as Area2D).monitoring = false

	sniff.global_position = Vector2(430.0, 360.0)
	sniff_enemies[2].global_position = Vector2(720.0, 360.0)
	sniff.blessing = SniffPlayerScript.MAX_BLESSING
	sniff.call("_begin_divine_annihilation")
	_expect(sniff.blessing == SniffPlayerScript.MAX_BLESSING and sniff.ultimate_cooldown == 0.0, "Divine Annihilation is blocked when Sniff lacks its high Mana cost")
	sniff.restore_mana(999.0)
	var annihilation_mana_before: float = sniff.mana
	sniff.call("_begin_divine_annihilation")
	_expect(is_equal_approx(sniff.mana, annihilation_mana_before - SniffPlayerScript.ANNIHILATION_MANA_COST), "Divine Annihilation consumes a large Mana payment")
	var crowned_health_before: float = sniff.health
	var blocked_damage: float = sniff.receive_hit(DamagePacketScript.enemy_melee(sniff_enemies[2], 44.0), Vector2.LEFT)
	_expect(blocked_damage == 0.0 and sniff.health == crowned_health_before, "crowned Divine Annihilation grants cast-window invulnerability")
	var ultimate_target_before: float = sniff_enemies[2].health
	sniff.call("_resolve_divine_annihilation")
	_expect(sniff.blessing == 0, "Divine Annihilation spends the full Blessing crown")
	_expect(sniff.ultimate_cooldown > 0.0, "Divine Annihilation starts its cooldown")
	_expect(sniff_enemies[2].health < ultimate_target_before, "Divine Annihilation damages enemies across its arena radius")

	sniff_world.queue_free()
	await process_frame

	var nad_world := Node2D.new()
	root.add_child(nad_world)
	var nad = NadPlayerScript.new()
	nad.position = Vector2(430.0, 360.0)
	nad_world.add_child(nad)
	nad.set("_using_gamepad", true)
	var nad_enemy = ReliquaryPursuerScript.new()
	nad_enemy.configure(nad, 1)
	nad_enemy.position = Vector2(570.0, 360.0)
	nad_enemy.move_speed = 0.0
	nad_world.add_child(nad_enemy)
	await process_frame

	nad_enemy.apply_mental_focus(10, 7.0)
	_expect(nad_enemy.get_mental_focus() == 5, "Mental Focus caps at five stacks")
	nad_enemy.apply_pierce_mark(10, 8.0)
	_expect(nad_enemy.get_pierce_marks() == 5, "Fin's Pierce Marks cap at five stacks")
	_expect(nad_enemy.consume_pierce_marks(3) == 3 and nad_enemy.get_pierce_marks() == 2, "Pierce Marks can be partially consumed by a finisher")
	nad_enemy.call("_begin_windup")
	_expect(nad_enemy.is_attack_winding_up(), "Fin can read an authoritative enemy windup")
	nad_enemy.apply_control_lock(0.3)
	nad_enemy.apply_control_lock(1.8)
	_expect(nad_enemy.is_control_locked(), "Eldritch control exposes an explicit enemy lock state")
	var remaining_before_extension: float = nad_enemy.get_control_lock_remaining()
	nad_enemy.extend_control_lock(0.6)
	_expect(nad_enemy.get_control_lock_remaining() > remaining_before_extension, "Mental Cascade can extend an active lock")
	var amplified_packet = DamagePacketScript.nad_foresee(nad, 0)
	var amplified_damage: float = nad_enemy.receive_hit(amplified_packet, Vector2.RIGHT)
	_expect(is_equal_approx(amplified_damage, amplified_packet.health_damage * 1.6), "five Focus stacks amplify damage to a locked target")
	_expect(is_equal_approx(nad.get_mana_regen_per_second(), NadPlayerScript.BASE_MANA_REGEN), "Nad has low passive Mana regeneration outside Mental Cascade")
	_expect(DamagePacketScript.nad_foresee(nad, 0).health_damage == 7.0 and DamagePacketScript.nad_anchor(nad).health_damage == 15.0, "Nad's control tools deal deliberately low health damage")

	nad.mana = NadPlayerScript.MAX_MANA
	nad_enemy.set("_control_lock_remaining", 0.0)
	nad.aim_direction = Vector2.RIGHT
	var foresee_health_before: float = nad_enemy.health
	nad.call("_begin_foresee")
	nad.call("_begin_foresee_active")
	for _frame: int in 3:
		await physics_frame
		await process_frame
	_expect(nad_enemy.health < foresee_health_before, "Foresee damages through its narrow collision probe")
	_expect(nad.mana >= NadPlayerScript.MAX_MANA - NadPlayerScript.FORESEE_COST and nad.mana < NadPlayerScript.MAX_MANA - NadPlayerScript.FORESEE_COST + 1.0, "Foresee receives only Nad's low passive Mana regeneration")

	nad.set("_state", NadPlayer.State.FREE)
	nad.mana = 40.0
	nad_enemy.global_position = nad.global_position + Vector2(150.0, 0.0)
	nad_enemy.apply_control_lock(2.0)
	nad.call("_begin_mental_cascade")
	for _frame: int in 18:
		await physics_frame
		await process_frame
	_expect(nad.get_cascade_regen_remaining() > 0.0, "a successful Mental Cascade activates Arcane Recursion")
	var cascade_mana_before: float = nad.mana
	nad.call("_tick_timers", 1.0)
	_expect(nad.mana >= cascade_mana_before + NadPlayerScript.BASE_MANA_REGEN + NadPlayerScript.CASCADE_MANA_REGEN - 0.01, "Mental Cascade temporarily supplies Nad's strong Mana regeneration")

	var anchor_enemy = ReliquaryPursuerScript.new()
	anchor_enemy.configure(nad, 1)
	anchor_enemy.position = Vector2(695.0, 360.0)
	anchor_enemy.move_speed = 0.0
	nad_world.add_child(anchor_enemy)
	await process_frame
	nad.mana = NadPlayerScript.MAX_MANA
	for _anchor_index: int in 3:
		nad.call("_cast_terrain_anchor")
	_expect(nad.get_anchor_count() == 3, "Terrain Anchors persist up to their three-anchor cap")
	for _frame: int in 3:
		await physics_frame
		await process_frame
	var anchor_health_before: float = anchor_enemy.health
	nad.call("_cast_terrain_anchor")
	_expect(nad.get_anchor_count() == 0, "a fourth Anchor command collapses the active lattice")
	_expect(anchor_enemy.health < anchor_health_before, "Anchor collapse damages through each persistent circular field")

	var conduit_enemy = ReliquaryPursuerScript.new()
	conduit_enemy.configure(nad, 1)
	conduit_enemy.position = Vector2(760.0, 480.0)
	conduit_enemy.move_speed = 0.0
	nad_world.add_child(conduit_enemy)
	await process_frame
	conduit_enemy.apply_mental_focus(3, 8.0)
	conduit_enemy.apply_control_lock(2.0)
	nad.mana = NadPlayerScript.MAX_MANA
	nad.call("_begin_arcane_conduit")
	var conduit_mana_after_cost: float = nad.mana
	var conduit_health_before: float = nad.health
	var conduit_blocked: float = nad.receive_hit(DamagePacketScript.enemy_melee(conduit_enemy, 42.0), Vector2.LEFT)
	_expect(conduit_blocked == 0.0 and nad.health == conduit_health_before, "Arcane Conduit grants cast-window invulnerability")
	for _frame: int in 2:
		await physics_frame
		await process_frame
	var conduit_target_before: float = conduit_enemy.health
	nad.set("_cascade_regen_remaining", 0.0)
	nad.mana = 10.0
	var conduit_mana_before_resolution: float = nad.mana
	nad.call("_resolve_arcane_conduit")
	_expect(is_equal_approx(nad.mana, conduit_mana_before_resolution), "Arcane Conduit no longer refunds Mana per controlled target")
	_expect(conduit_enemy.health < conduit_target_before, "Arcane Conduit cashes out a locked target across its arena sensor")
	_expect(nad.ultimate_cooldown > 0.0, "Arcane Conduit starts its cooldown")
	_expect(
		DamagePacketScript.nad_conduit(nad, 3, true).health_damage > DamagePacketScript.nad_conduit(nad, 3, false).health_damage,
		"Arcane Conduit explicitly rewards pre-locked targets"
	)

	nad.set("_state", NadPlayer.State.FREE)
	nad.set_survivor_mode(true)
	nad.set_survivor_ability_progress(&"signature", 20, 5, 1.62, 0.74)
	var execute_enemy = ReliquaryPursuerScript.new()
	execute_enemy.configure(nad, 0)
	execute_enemy.global_position = nad.global_position + Vector2(90.0, 0.0)
	nad_world.add_child(execute_enemy)
	await process_frame
	execute_enemy.process_mode = Node.PROCESS_MODE_DISABLED
	execute_enemy.health = execute_enemy.max_health * 0.30
	_expect(is_equal_approx(nad.get_mantle_execute_threshold(), 0.32), "rank-twenty Mantle raises its tentacle execute threshold to 32 percent")
	var mantle_execution_count := int(nad.call("_execute_mantle_tentacles", nad.global_position, 5))
	_expect(mantle_execution_count >= 1, "rank-twenty Mantle tentacles acquire nearby enemies below their execute threshold")
	_expect(not execute_enemy.is_alive(), "Mantle tentacle execution immediately kills its acquired target")
	nad.set_survivor_ability_progress(&"ultimate", 20, 5, 1.62, 0.74)
	nad.mana = NadPlayerScript.MAX_MANA
	nad.ultimate_cooldown = 0.0
	nad.call("_begin_arcane_conduit")
	_expect(nad.is_eldritch_form_active() and is_equal_approx(nad.get_eldritch_form_remaining(), NadPlayerScript.ELDRITCH_FORM_DURATION), "rank-twenty Arcane Conduit transforms Nad for ten seconds")
	_expect(is_equal_approx(nad.ultimate_cooldown, NadPlayerScript.ELDRITCH_FORM_COOLDOWN), "Eldritch Form starts a true ninety-second cooldown")
	var eldritch_cooldown_before: float = nad.ultimate_cooldown
	nad.call("_tick_timers", 1.0)
	_expect(is_equal_approx(nad.ultimate_cooldown, eldritch_cooldown_before - 1.0), "Eldritch Form cooldown is not shortened by ability-rank cooldown scaling")

	nad_world.queue_free()
	await process_frame

	var fin_world := Node2D.new()
	root.add_child(fin_world)
	var fin = FinPlayerScript.new()
	fin.position = Vector2(430.0, 360.0)
	fin_world.add_child(fin)
	fin.set("_using_gamepad", true)
	fin.aim_direction = Vector2.RIGHT
	var fin_enemy = ReliquaryPursuerScript.new()
	fin_enemy.configure(fin, 1)
	fin_enemy.position = Vector2(570.0, 360.0)
	fin_enemy.move_speed = 0.0
	fin_world.add_child(fin_enemy)
	await process_frame

	_expect(fin.get_form() == FinPlayerScript.Form.NIGHTBLADE, "Fin opens in Nightblade form")
	fin.cycle_form()
	_expect(fin.get_form() == FinPlayerScript.Form.ARBALEST, "tap switching cycles Fin's form")
	_expect(fin.get_form_for_direction(Vector2.DOWN) == FinPlayerScript.Form.HUNTSMAN, "held form selection maps down to Huntsman")
	_expect(fin.get_form_for_direction(Vector2.LEFT) == FinPlayerScript.Form.ARTIFICER, "held form selection maps left to Artificer")

	fin.select_form(FinPlayerScript.Form.NIGHTBLADE)
	fin_enemy.apply_pierce_mark(5, 8.0)
	var pierce_health_before: float = fin_enemy.health
	fin.set("_active_action", &"mind_pierce")
	fin.set("_signature_charge", 1.0)
	fin.call("_release_signature")
	for _frame: int in 3:
		await physics_frame
		await process_frame
	_expect(fin_enemy.health < pierce_health_before, "Mind Pierce damages through its collision thrust")
	_expect(fin_enemy.get_pierce_marks() == 0, "Mind Pierce consumes prepared Pierce Marks")
	fin.call("_cast_umbral_veil")
	_expect(fin.is_concealed(), "Umbral Veil enters an explicit concealment state")
	_expect(is_equal_approx(fin.mana, FinPlayerScript.MAX_MANA - FinPlayerScript.VEIL_MANA_COST), "Fin spends Mana on shadow magic")
	fin_enemy.call("_begin_windup")
	fin_enemy.call("_physics_process", 0.02)
	_expect(not fin_enemy.is_attack_winding_up(), "concealment interrupts enemy windup authority")

	fin.select_form(FinPlayerScript.Form.ARBALEST)
	fin.set("_crossbow_loaded", true)
	fin.set("_knockback_velocity", Vector2.ZERO)
	fin.call("_begin_primary", 0)
	fin.call("_resolve_primary")
	_expect(not fin.is_crossbow_loaded() and fin.get_crossbow_reload() > 0.0, "Crossbow fire enters a real reload lockout")
	_expect((fin.get("_knockback_velocity") as Vector2).x < 0.0, "Crossbow fire applies directional recoil")
	fin.call("_tick_timers", FinPlayerScript.CROSSBOW_RELOAD_TIME + 0.1)
	_expect(fin.is_crossbow_loaded(), "Crossbow reload completes while other forms are available")
	_expect(
		DamagePacketScript.fin_arrow(fin, 1.0, 1.0).health_damage > DamagePacketScript.fin_arrow(fin, 1.0, 0.0).health_damage,
		"Huntsman arrows reward authored long range"
	)

	fin.select_form(FinPlayerScript.Form.HUNTSMAN)
	fin.aim_direction = Vector2.RIGHT
	fin_enemy.position = Vector2(665.0, 360.0)
	fin_enemy.health = fin_enemy.max_health
	fin_enemy.resolve = fin_enemy.max_resolve
	fin.call("_cast_shadow_bind")
	_expect(fin.get_trap_count() == 1, "Shadow Bind places a persistent collision trap")
	for _frame: int in 3:
		await physics_frame
		await process_frame
	_expect(fin_enemy.is_control_locked() and fin_enemy.get_pierce_marks() >= 2, "Shadow Bind roots and marks an overlapping enemy")
	var daggers_before: int = fin.get_throwing_dagger_count()
	fin.call("_throw_dagger")
	_expect(fin.get_throwing_dagger_count() == daggers_before - 1, "Throwing Daggers consume finite regenerating charges")

	fin.select_form(FinPlayerScript.Form.ARTIFICER)
	fin.health = 120.0
	var tool_mana_before: float = fin.mana
	var potions_before: int = fin.get_potion_count()
	_expect(fin.use_potion(FinPlayerScript.Potion.MENDING), "Artificer can deliberately select a potion")
	_expect(fin.health > 120.0 and fin.get_potion_count() == potions_before - 1, "Mending Draught heals and consumes one supply")
	var smoke_before: int = fin.get_smoke_bomb_count()
	fin.call("_throw_smoke_bomb")
	_expect(fin.get_smoke_bomb_count() == smoke_before - 1 and fin.is_concealed(), "Smoke Bomb creates concealment and consumes a charge")
	_expect(is_equal_approx(fin.mana, tool_mana_before), "Fin's potions and physical tools do not spend Mana")
	fin.set("mutivarg_cooldown", 0.0)
	var mutivarg_mana_before: float = fin.mana
	fin.call("_begin_signature")
	_expect(is_equal_approx(fin.mana, mutivarg_mana_before - FinPlayerScript.MUTIVARG_MANA_COST), "Mutivarg's magical field spends Mana")
	fin.set("_signature_charge", 1.0)
	fin.call("_release_signature")
	var has_mutivarg_field := false
	for child: Node in fin_world.get_children():
		if child.get_script() == FinFieldScript and int(child.get("_kind")) == FinFieldScript.Kind.MUTIVARG:
			has_mutivarg_field = true
			break
	_expect(has_mutivarg_field and fin.mutivarg_cooldown > 0.0, "Mutivarg's Rod deploys a persistent compression field")

	fin.set("_state", FinPlayerScript.State.FREE)
	fin.set("_veil_time", 0.0)
	fin.set("_smoke_veil_time", 0.0)
	fin.set("_invulnerable_time", 0.0)
	fin.global_position = Vector2(300.0, 600.0)
	fin_enemy.global_position = Vector2(390.0, 600.0)
	fin_enemy.consume_pierce_marks(FinPlayerScript.MAX_PIERCE_MARKS)
	var step_target_health_before: float = fin_enemy.health
	fin_enemy.call("_begin_windup")
	fin.aim_direction = Vector2.RIGHT
	var step_mana_before: float = fin.mana
	fin.call("_begin_umbral_step")
	_expect(is_equal_approx(fin.mana, step_mana_before - FinPlayerScript.UMBRAL_STEP_MANA_COST), "Umbral Step spends Mana")
	_expect(fin.is_umbral_stepping() and fin.is_concealed(), "Umbral Step makes Fin unseen for its escape window")
	_expect(fin.collision_mask == 4 and not (fin.get("_attack_area") as Area2D).monitoring, "Umbral Step phases enemy bodies and disables offense")
	_expect(is_equal_approx(fin.umbral_step_cooldown, FinPlayerScript.UMBRAL_STEP_COOLDOWN), "Umbral Step starts its authored cooldown")
	Input.action_press(&"move_right")
	for _frame: int in 14:
		await physics_frame
		await process_frame
	Input.action_release(&"move_right")
	_expect(fin.global_position.x > fin_enemy.global_position.x + 20.0, "Umbral Step runs through an enemy at high speed")
	_expect(fin.velocity.length() >= FinPlayerScript.MOVE_SPEED * FinPlayerScript.UMBRAL_STEP_SPEED_MULTIPLIER * 0.95, "Umbral Step grants a large movement-speed boost")
	_expect(not fin_enemy.is_attack_winding_up(), "unseen Umbral Step interrupts enemy attack acquisition")
	_expect(fin_enemy.health == step_target_health_before and fin_enemy.get_pierce_marks() == 0, "Umbral Step deals no damage and applies no Pierce Marks")
	fin.call("_update_state", FinPlayerScript.UMBRAL_STEP_DURATION)
	_expect(not fin.is_umbral_stepping() and fin.collision_mask == 2 | 4, "Umbral Step restores normal collision when it ends")
	fin.call("_begin_umbral_step")
	_expect(not fin.is_umbral_stepping(), "Umbral Step cannot restart during its cooldown")

	var spawned_fin_projectile := false
	for child: Node in fin_world.get_children():
		if child.get_script() == FinProjectileScript:
			spawned_fin_projectile = true
			break
	_expect(spawned_fin_projectile, "Fin's ranged forms spawn collision-backed projectiles")
	fin_world.queue_free()
	await process_frame

	if _failures.is_empty():
		print("PASS: %d Arcane Impact core checks." % _check_count)
		quit(0)
		return

	for failure: String in _failures:
		push_error("FAIL: %s" % failure)
	quit(1)


func _expect(condition: bool, label: String) -> void:
	_check_count += 1
	if not condition:
		_failures.append(label)