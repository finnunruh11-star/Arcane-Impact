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
	kat.call("_cast_leech_choir")
	_expect(kat.get_mote_count() == 3, "Leech Choir respects its three-summon cap")
	kat.call("_cast_mourning_halo")
	_expect(kat.is_halo_active(), "Mourning Halo creates its collision-backed aura")
	enemy.apply_curse(10, 6.0)
	_expect(enemy.get_curse_stacks() == 5, "enemy curse intensity caps at five stacks")
	var enemy_health_before_ultimate: float = enemy.health
	kat.vitality = KatPlayerScript.MAX_VITALITY
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
	sniff.on_lightning_dart_hit(sniff_enemies[0], sniff_enemies[0].global_position, Vector2.RIGHT, 0)
	_expect(sniff_enemies[0].health < primary_health_before, "Lightning Dart damages its primary target")
	_expect(sniff_enemies[1].health < chain_health_before, "Lightning Dart chains to a nearby second target")
	_expect(sniff.get_blessing_count() == 2, "dart and chain hits each build Blessing")

	sniff.aim_direction = Vector2.RIGHT
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

	sniff.global_position = Vector2(430.0, 360.0)
	sniff_enemies[2].global_position = Vector2(720.0, 360.0)
	sniff.blessing = SniffPlayerScript.MAX_BLESSING
	sniff.call("_begin_divine_annihilation")
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