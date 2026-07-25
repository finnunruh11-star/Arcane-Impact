extends SceneTree


const HERO_SCENES := [
	preload("res://scenes/arena/kat_combat_slice.tscn"),
	preload("res://scenes/arena/sniff_combat_slice.tscn"),
	preload("res://scenes/arena/nad_combat_slice.tscn"),
	preload("res://scenes/arena/fin_combat_slice.tscn"),
]
const HERO_NAMES := ["Kat", "Sniff", "Nad", "Fin"]
const ProgressionScript := preload("res://scripts/survivors/survivor_progression.gd")
const StatStateScript := preload("res://scripts/survivors/survivor_stat_state.gd")

var _failures: Array[String] = []
var _check_count := 0


func _init() -> void:
	call_deferred(&"_run")


func _run() -> void:
	_check_progression_model()
	_check_adaptive_spawn_pacing()
	_check_arena_layout()
	await _check_ranged_enemy_tactics()
	await _check_tier_behavior_contracts()
	await _check_primary_evolution_contracts()
	for hero_index: int in HERO_SCENES.size():
		if not await _check_hero_run(hero_index):
			_break_with_cleanup()
			return
	await _check_level_up()
	await _check_timed_victory()
	if _failures.is_empty():
		print("PASS: %d Survivors run checks." % _check_count)
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)


func _check_arena_layout() -> void:
	_expect(ArenaBackdrop.PLAYABLE_RECT.size.x >= 2400.0 and ArenaBackdrop.PLAYABLE_RECT.size.y >= 1400.0, "Survivors arena is substantially larger than one viewport")
	_expect(ArenaBackdrop.STRUCTURE_RECTS.size() >= 6, "expanded arena contains several solid structures")
	var all_structures_inside := true
	for structure: Rect2 in ArenaBackdrop.STRUCTURE_RECTS:
		all_structures_inside = all_structures_inside and ArenaBackdrop.PLAYABLE_RECT.encloses(structure)
	_expect(all_structures_inside and ArenaBackdrop.is_position_clear(Vector2(640.0, 360.0), 48.0), "structures stay inside the arena and leave the player spawn clear")
	var spawn_probe := SurvivorRun.new()
	var spawn_rng := spawn_probe.get("_rng") as RandomNumberGenerator
	spawn_rng.seed = 73021
	var spawn_bounds := ArenaBackdrop.PLAYABLE_RECT.grow(-SurvivorRun.SPAWN_EDGE_INSET)
	var represented_sides: Dictionary = {}
	var all_spawns_clear := true
	for _spawn_index: int in 12:
		var spawn_position: Vector2 = spawn_probe.call(&"_random_edge_position")
		all_spawns_clear = all_spawns_clear and ArenaBackdrop.is_position_clear(spawn_position, SurvivorRun.SPAWN_CLEARANCE)
		var side_distances := [
			absf(spawn_position.y - spawn_bounds.position.y),
			absf(spawn_position.x - spawn_bounds.end.x),
			absf(spawn_position.y - spawn_bounds.end.y),
			absf(spawn_position.x - spawn_bounds.position.x),
		]
		var closest_side := 0
		for side_index: int in range(1, side_distances.size()):
			if float(side_distances[side_index]) < float(side_distances[closest_side]):
				closest_side = side_index
		represented_sides[closest_side] = true
	_expect(all_spawns_clear, "every perimeter spawn satisfies the same arena clearance used by enemy bodies")
	_expect(represented_sides.size() == 4, "the shuffled perimeter bag distributes enemies across all four arena sides")
	spawn_probe.free()


func _check_adaptive_spawn_pacing() -> void:
	var pacing := SurvivorRun.new()
	pacing.set("_run_time", 40.0)
	var no_kills: Array[float] = []
	pacing.set("_recent_kill_times", no_kills)
	var low_target := pacing.get_spawn_target_count()
	var low_interval := pacing.get_spawn_interval()
	var fast_kills: Array[float] = []
	for kill_index: int in 30:
		fast_kills.append(10.0 + float(kill_index))
	pacing.set("_recent_kill_times", fast_kills)
	var high_target := pacing.get_spawn_target_count()
	var high_interval := pacing.get_spawn_interval()
	_expect(low_target == 1 and high_target == 2, "the opening phase presents one duel and permits only one performance-pressure add")
	_expect(low_interval > high_interval, "faster clearing shortens refills inside the current phase")
	pacing.set("_run_time", 520.0)
	var climax_target := pacing.get_spawn_target_count()
	_expect(climax_target > high_target and climax_target <= SurvivorRun.MAX_ENEMIES, "elapsed phases raise the population ceiling without exceeding the global cap")
	var director := SurvivorSpawnDirector.new()
	var two_ranged: Array[int] = [ReliquaryPursuer.Role.BONE_ARCANIST, ReliquaryPursuer.Role.GRAVE_DEADEYE]
	_expect(not director.can_spawn_role(20.0, [], ReliquaryPursuer.Role.BONE_ARCANIST), "ranged roles stay locked during the opening duel phase")
	_expect(not director.can_spawn_role(250.0, two_ranged, ReliquaryPursuer.Role.BONE_ARCANIST), "the pressure phase enforces its two-ranged hard cap")
	var early_scaling: Dictionary = director.get_scaling(0.0)
	var late_scaling: Dictionary = director.get_scaling(600.0)
	_expect(float(late_scaling[&"health"]) > float(early_scaling[&"health"]) and float(late_scaling[&"damage"]) > float(early_scaling[&"damage"]), "enemy durability and damage scale along smooth run-time curves")
	pacing.free()


func _check_ranged_enemy_tactics() -> void:
	var player := KatPlayer.new()
	root.add_child(player)
	await process_frame
	player.process_mode = Node.PROCESS_MODE_DISABLED
	player.global_position = Vector2(640.0, 360.0)

	var arcanist := ReliquaryPursuer.new()
	arcanist.configure(player, ReliquaryPursuer.Role.BONE_ARCANIST)
	arcanist.global_position = Vector2(1340.0, 360.0)
	root.add_child(arcanist)
	await process_frame
	arcanist.process_mode = Node.PROCESS_MODE_DISABLED
	var far_to_player := player.global_position - arcanist.global_position
	var approach_direction: Vector2 = arcanist.call(&"_get_chase_direction", far_to_player)
	_expect(approach_direction.dot(far_to_player.normalized()) > 0.70, "ranged enemies approach decisively before entering their firing band")
	_expect(not bool(arcanist.call(&"_should_begin_attack", 180.0)) and bool(arcanist.call(&"_should_begin_attack", 360.0)) and not bool(arcanist.call(&"_should_begin_attack", 540.0)), "the Arcanist fires only from a readable engagement band")

	arcanist.global_position = Vector2(1040.0, 360.0)
	var deadeye := ReliquaryPursuer.new()
	deadeye.configure(player, ReliquaryPursuer.Role.GRAVE_DEADEYE)
	deadeye.global_position = arcanist.global_position + Vector2(120.0, 0.0)
	root.add_child(deadeye)
	await process_frame
	deadeye.process_mode = Node.PROCESS_MODE_DISABLED
	var separation_direction: Vector2 = arcanist.call(&"_get_horde_separation_direction")
	var away_from_deadeye := (arcanist.global_position - deadeye.global_position).normalized()
	_expect(separation_direction.dot(away_from_deadeye) > 0.90, "ranged enemies separate before their sprites or firing lanes clump")

	arcanist.set("_state", ReliquaryPursuer.State.RECOVERY)
	arcanist.set("_state_time", 1.0)
	arcanist.set("_reposition_remaining", 0.75)
	var recovery_start := arcanist.global_position
	arcanist.process_mode = Node.PROCESS_MODE_INHERIT
	await physics_frame
	await process_frame
	arcanist.process_mode = Node.PROCESS_MODE_DISABLED
	_expect(arcanist.global_position.distance_to(recovery_start) > 0.5, "ranged enemies relocate during post-shot recovery instead of becoming turrets")

	var enemy_sprite := arcanist.get_node(^"EnemySprite") as AnimatedSprite2D
	arcanist.set("_state", ReliquaryPursuer.State.CHASE)
	arcanist.set("_telegraph_time", 0.13)
	arcanist.velocity = Vector2(-arcanist.move_speed, arcanist.move_speed * 0.25)
	for _animation_step: int in 4:
		arcanist.call(&"_update_sprite", 0.05)
	_expect(enemy_sprite.animation == &"run" and enemy_sprite.position.distance_to(Vector2(0.0, -17.0)) > 0.4, "enemy locomotion uses its run cycle with a grounded procedural gait")
	arcanist.call(&"_begin_windup")
	arcanist.set("_state_time", arcanist.windup_duration * 0.45)
	for _animation_step: int in 4:
		arcanist.call(&"_update_sprite", 0.05)
	_expect(enemy_sprite.animation == &"idle" and absf(enemy_sprite.scale.x - enemy_sprite.scale.y) > 0.10, "enemy windups have a distinct anticipation pose instead of a static idle frame")

	var orb := EnemyProjectile.new()
	orb.configure(arcanist, player, Vector2.LEFT, EnemyProjectile.Kind.ARCANE_ORB, 10.0)
	root.add_child(orb)
	var bolt := EnemyProjectile.new()
	bolt.configure(deadeye, player, Vector2.LEFT, EnemyProjectile.Kind.DEADEYE_BOLT, 10.0)
	root.add_child(bolt)
	await process_frame
	orb.process_mode = Node.PROCESS_MODE_DISABLED
	bolt.process_mode = Node.PROCESS_MODE_DISABLED
	_expect(orb.get_node_or_null(^"ProjectileVfx") is PixelSheetEffect and bolt.get_node_or_null(^"ProjectileVfx") is PixelSheetEffect, "both ranged attacks use authored animated projectile effects")

	orb.queue_free()
	bolt.queue_free()
	arcanist.queue_free()
	deadeye.queue_free()
	player.queue_free()
	await process_frame


func _check_progression_model() -> void:
	var progression = ProgressionScript.new()
	progression.configure(1)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var options: Array[Dictionary] = progression.roll_options(rng, 6)
	var option_ids: Dictionary = {}
	var stat_count := 0
	var ability_count := 0
	for option: Dictionary in options:
		option_ids[option[&"id"]] = true
		if option[&"kind"] == &"ability":
			ability_count += 1
		else:
			stat_count += 1
	_expect(options.size() == 6 and option_ids.size() == 6, "level-up rolls six unique choices")
	_expect(stat_count == 3 and ability_count == 3, "every six-choice roll mixes three stats with three hero abilities")
	var expected_stats := {
		&"strength": true,
		&"dexterity": true,
		&"intelligence": true,
		&"mana": true,
		&"vitality": true,
		&"luck": true,
	}
	var catalog_is_original_stats := true
	for stat: Dictionary in ProgressionScript.STAT_CATALOG:
		catalog_is_original_stats = catalog_is_original_stats and expected_stats.has(stat[&"id"])
	_expect(catalog_is_original_stats and ProgressionScript.STAT_CATALOG.size() == expected_stats.size(), "boons use Strength, Dexterity, Intelligence, Mana, Vitality, and Luck")
	_expect(is_equal_approx(progression.get_double_upgrade_chance(), 0.15), "every boon starts with a 15 percent double-upgrade chance")
	progression.apply_pick(&"luck", 2)
	_expect(is_equal_approx(progression.get_double_upgrade_chance(), 0.25), "Luck increases the double-upgrade chance")
	var stats = StatStateScript.new()
	stats.add_rank(&"strength")
	stats.add_rank(&"dexterity")
	stats.add_rank(&"intelligence")
	stats.add_rank(&"mana")
	stats.add_rank(&"vitality")
	stats.add_rank(&"luck")
	_expect(is_equal_approx(stats.get_resolve_multiplier(), 1.04), "Strength slightly increases maximum Resolve")
	_expect(is_equal_approx(stats.get_move_speed_multiplier(), 1.03), "Dexterity slightly increases movement speed")
	_expect(is_equal_approx(stats.get_scaling_multiplier(&"intelligence"), 1.12), "Intelligence scales spell damage")
	_expect(is_equal_approx(stats.get_mana_multiplier(), 1.15) and is_equal_approx(stats.get_mana_regen_multiplier(), 1.12), "Mana increases capacity and regeneration")
	_expect(is_equal_approx(StatStateScript.new().get_health_regen(), 1.5), "every hero starts with useful health regeneration before taking Vitality")
	_expect(is_equal_approx(stats.get_health_multiplier(), 1.10) and is_equal_approx(stats.get_health_regen(), 2.5), "Vitality increases health and adds to base health regeneration")
	_expect(is_equal_approx(stats.get_critical_chance(), 0.04) and is_equal_approx(stats.get_critical_damage(), 1.60), "Luck increases critical chance and critical damage")
	var complete_tier_catalog := true
	var current_kits_are_tier_three := true
	for hero_abilities: Array in ProgressionScript.HERO_ABILITIES:
		complete_tier_catalog = complete_tier_catalog and hero_abilities.size() == 5
		for ability_data: Dictionary in hero_abilities:
			var tiers := ability_data[&"tiers"] as Array
			complete_tier_catalog = complete_tier_catalog and tiers.size() == 5
			current_kits_are_tier_three = current_kits_are_tier_three and tiers.size() >= 3 and String(tiers[2]).to_lower().contains("full")
	_expect(complete_tier_catalog, "all four heroes expose five abilities with five authored tiers each")
	_expect(current_kits_are_tier_three, "the original full-strength ability behavior remains tier three")
	var nad_horror_escalates := true
	for ability_data: Dictionary in ProgressionScript.HERO_ABILITIES[2]:
		var tiers := ability_data[&"tiers"] as Array
		var late_horror := (String(tiers[3]) + " " + String(tiers[4])).to_lower()
		nad_horror_escalates = nad_horror_escalates and (late_horror.contains("void") or late_horror.contains("tentacle") or late_horror.contains("tendril") or late_horror.contains("eye") or late_horror.contains("abyss") or late_horror.contains("rift") or late_horror.contains("eldritch") or late_horror.contains("maw"))
	_expect(nad_horror_escalates, "every Nad ability becomes explicitly more eldritch at late tiers")
	_expect(progression.get_rank(&"signature") == 0 and not progression.is_unlocked(&"signature"), "offensive active abilities start locked")
	_expect(progression.get_rank(&"evade") == 1 and progression.is_unlocked(&"evade"), "every hero starts with its escape ability at rank one")
	var first_pick: Dictionary = progression.apply_pick(&"signature")
	_expect(first_pick[&"rank"] == 1 and first_pick[&"tier"] == 1 and progression.is_unlocked(&"signature"), "first ability pick unlocks rank one at tier one")
	var second_pick: Dictionary = progression.apply_pick(&"signature")
	_expect(second_pick[&"rank"] == 2 and progression.get_ability_power_multiplier(&"signature") > 0.58, "repeat ability picks improve its rank and power")
	progression.apply_pick(&"ability_1")
	progression.apply_pick(&"signature", 3)
	_expect(progression.get_ability_tier(&"signature") == 2 and progression.get_ability_tier(&"ability_1") == 1, "a skill evolves at rank five without upgrading its rank-one neighbors")
	for milestone: Array in [[1, 1], [5, 2], [10, 3], [15, 4], [20, 5]]:
		progression.set_run_level(int(milestone[0]))
		_expect(progression.get_tier() == int(milestone[1]), "run level %d selects basic-attack tier %d" % milestone)
	_expect(is_equal_approx(progression.get_basic_attack_power_multiplier(), 2.15), "basic attacks gain a large independent power evolution by level twenty")
	_expect(progression.get_ability_tier(&"signature") == 2 and progression.get_ability_tier(&"ability_1") == 1, "run levels do not upgrade active abilities")
	var sniff_options: Array[Dictionary] = progression.roll_options(rng, 11)
	var found_heavenfall := false
	for option: Dictionary in sniff_options:
		if option[&"id"] == &"signature":
			found_heavenfall = String(option[&"title"]).contains("HEAVENFALL")
	_expect(found_heavenfall, "hero ability choices use the selected hero's identity")


func _check_tier_behavior_contracts() -> void:
	var sniff_tier_one := SniffPlayer.new()
	root.add_child(sniff_tier_one)
	await process_frame
	sniff_tier_one.set_survivor_mode(true)
	sniff_tier_one.set_survivor_ability_progress(&"signature", 1, 1, 0.58, 1.32)
	sniff_tier_one.aim_direction = Vector2.RIGHT
	sniff_tier_one.call(&"_begin_heavenfall")
	_expect(is_equal_approx(sniff_tier_one.get_active_spell_radius(), 230.0), "tier-one Heavenfall begins with a compact impact radius")
	sniff_tier_one.queue_free()
	await process_frame

	var sniff_tier_three := SniffPlayer.new()
	root.add_child(sniff_tier_three)
	await process_frame
	sniff_tier_three.set_survivor_mode(true)
	sniff_tier_three.set_survivor_ability_progress(&"signature", 1, 3, 1.0, 1.0)
	sniff_tier_three.aim_direction = Vector2.RIGHT
	sniff_tier_three.call(&"_begin_heavenfall")
	_expect(is_equal_approx(sniff_tier_three.get_active_spell_radius(), SniffPlayer.HEAVENFALL_BASE_RADIUS), "tier-three Heavenfall retains its full baseline storm radius")
	sniff_tier_three.queue_free()
	await process_frame

	var sniff_tier_five := SniffPlayer.new()
	root.add_child(sniff_tier_five)
	await process_frame
	sniff_tier_five.set_survivor_mode(true)
	sniff_tier_five.set_survivor_ability_progress(&"signature", 1, 5, 1.62, 0.74)
	sniff_tier_five.global_position = Vector2(200.0, 360.0)
	sniff_tier_five.aim_direction = Vector2.RIGHT
	var distant_storm_target := ReliquaryPursuer.new()
	distant_storm_target.configure(sniff_tier_five, 1)
	distant_storm_target.max_health = 1200.0
	distant_storm_target.health = distant_storm_target.max_health
	distant_storm_target.global_position = Vector2(1300.0, 360.0)
	root.add_child(distant_storm_target)
	await process_frame
	distant_storm_target.process_mode = Node.PROCESS_MODE_DISABLED
	var distant_target_health := distant_storm_target.health
	sniff_tier_five.call(&"_set_using_gamepad", true)
	sniff_tier_five.aim_direction = Vector2.RIGHT
	sniff_tier_five.set("_backfire_override", 0)
	sniff_tier_five.call(&"_begin_heavenfall")
	_expect(is_equal_approx(sniff_tier_five.get_active_spell_radius(), 500.0), "tier-five Heavenfall grows beyond its tier-three impact geometry")
	sniff_tier_five.call(&"_resolve_heavenfall")
	_expect(distant_storm_target.health < distant_target_health, "tier-five Heavenfall reaches and damages distant crowds")
	distant_storm_target.queue_free()
	sniff_tier_five.queue_free()
	await process_frame

	var kat_tier_one := KatPlayer.new()
	root.add_child(kat_tier_one)
	await process_frame
	kat_tier_one.set_survivor_mode(true)
	kat_tier_one.set_survivor_ability_progress(&"ability_1", 1, 1, 0.58, 1.32)
	kat_tier_one.call(&"_cast_leech_choir")
	var tier_one_motes: Array = kat_tier_one.get("_motes")
	_expect(tier_one_motes.size() == 1, "tier-one Leech Choir summons exactly one Mote")
	for mote: Node in tier_one_motes:
		mote.queue_free()
	kat_tier_one.queue_free()
	await process_frame

	var anchor_tier_one := TerrainAnchor.new()
	anchor_tier_one.configure(null, 1)
	var anchor_tier_five := TerrainAnchor.new()
	anchor_tier_five.configure(null, 5)
	_expect(anchor_tier_one.get_radius() < TerrainAnchor.RADIUS and anchor_tier_five.get_radius() > TerrainAnchor.RADIUS, "Terrain Anchor control geometry grows below and above tier three")
	anchor_tier_one.free()
	anchor_tier_five.free()

	var fin_tier_one := FinPlayer.new()
	root.add_child(fin_tier_one)
	await process_frame
	fin_tier_one.set_survivor_mode(true)
	fin_tier_one.set_survivor_ability_progress(&"signature", 1, 1, 0.58, 1.32)
	fin_tier_one.call(&"_begin_signature")
	var tier_one_is_charging := fin_tier_one.get_state_label().begins_with("Charging")
	fin_tier_one.queue_free()
	await process_frame
	var fin_tier_three := FinPlayer.new()
	root.add_child(fin_tier_three)
	await process_frame
	fin_tier_three.set_survivor_mode(true)
	fin_tier_three.set_survivor_ability_progress(&"signature", 1, 3, 1.0, 1.0)
	fin_tier_three.call(&"_begin_signature")
	_expect(not tier_one_is_charging and fin_tier_three.get_state_label().begins_with("Charging"), "Fin signatures are quick at tier one and retain full charging at tier three")
	fin_tier_three.queue_free()
	await process_frame


func _check_primary_evolution_contracts() -> void:
	var kat := KatPlayer.new()
	root.add_child(kat)
	await process_frame
	kat.set_survivor_mode(true)
	kat.set_survivor_basic_attack_progress(4, 1.75)
	var wave_target := ReliquaryPursuer.new()
	wave_target.configure(kat, 0)
	root.add_child(wave_target)
	await process_frame
	wave_target.process_mode = Node.PROCESS_MODE_DISABLED
	wave_target.global_position = kat.global_position + Vector2(220.0, 0.0)
	kat.aim_direction = Vector2.RIGHT
	var wave_health_before: float = wave_target.health
	kat.call("_resolve_primary_finisher_wave", 4)
	_expect(wave_target.health < wave_health_before, "level-fifteen Kat basic finisher evolves into a ranged shockwave")
	wave_target.queue_free()
	kat.queue_free()
	await process_frame

	var nad := NadPlayer.new()
	root.add_child(nad)
	await process_frame
	nad.set_survivor_mode(true)
	nad.set_survivor_basic_attack_progress(3, 1.45)
	nad.global_position = Vector2(300.0, 300.0)
	nad.aim_direction = Vector2.RIGHT
	var foresee_targets: Array[ReliquaryPursuer] = []
	var target_offsets: Array[Vector2] = [Vector2(100.0, -12.0), Vector2(165.0, 12.0)]
	for target_offset: Vector2 in target_offsets:
		var target := ReliquaryPursuer.new()
		target.configure(nad, 0)
		root.add_child(target)
		foresee_targets.append(target)
	await process_frame
	for target_index: int in foresee_targets.size():
		var target := foresee_targets[target_index]
		target.process_mode = Node.PROCESS_MODE_DISABLED
		target.global_position = nad.global_position + target_offsets[target_index]
	nad.process_mode = Node.PROCESS_MODE_DISABLED
	nad.aim_direction = Vector2.RIGHT
	var foresee_candidates: Array[Node2D] = []
	for target: ReliquaryPursuer in foresee_targets:
		foresee_candidates.append(target)
	nad.call("_resolve_foresee_candidates", foresee_candidates, 3)
	_expect(foresee_targets[0].get_mental_focus() > 0 and foresee_targets[1].get_mental_focus() > 0, "level-ten Foresee evolves from one target into a two-mind probe")
	for target: ReliquaryPursuer in foresee_targets:
		target.queue_free()
	nad.queue_free()
	await process_frame

	var fin := FinPlayer.new()
	root.add_child(fin)
	await process_frame
	fin.set_survivor_mode(true)
	fin.set_survivor_basic_attack_progress(5, 2.15)
	fin.call("_queue_primary_evolution_echoes")
	var primary_echoes: Array = fin.get("_primary_echo_queue")
	_expect(primary_echoes.size() == 3, "level-twenty Fin basic attacks invoke the other three forms")
	fin.queue_free()
	await process_frame


func _check_hero_run(hero_index: int) -> bool:
	var scene = HERO_SCENES[hero_index].instantiate()
	scene.set(&"audio_enabled", false)
	root.add_child(scene)
	for _frame: int in 8:
		await process_frame
	var player := scene.get_player() as Node2D
	_expect(is_instance_valid(player) and player.name == HERO_NAMES[hero_index], "%s run creates the selected hero" % HERO_NAMES[hero_index])
	_expect(scene.get_enemy_count() == 1, "%s run opens with one readable duel opponent" % HERO_NAMES[hero_index])
	var offensive_slots_locked := true
	for slot: StringName in ProgressionScript.ABILITY_SLOTS:
		if slot != &"evade":
			offensive_slots_locked = offensive_slots_locked and not bool(player.call(&"is_survivor_ability_unlocked", slot))
	_expect(offensive_slots_locked and bool(player.call(&"is_survivor_ability_unlocked", &"evade")), "%s starts with its basic attack and escape option" % HERO_NAMES[hero_index])
	_expect(float(player.call(&"get_survivor_health_regen")) >= 1.5, "%s regenerates health without a Vitality pick" % HERO_NAMES[hero_index])

	var targets: Array[ReliquaryPursuer] = []
	for enemy_node: Node in get_nodes_in_group(&"enemies"):
		if scene.is_ancestor_of(enemy_node) and enemy_node is ReliquaryPursuer:
			targets.append(enemy_node as ReliquaryPursuer)
	if targets.is_empty():
		_failures.append("%s run did not create an enemy target" % HERO_NAMES[hero_index])
		scene.queue_free()
		for _frame: int in 6:
			await process_frame
		return false
	for enemy: ReliquaryPursuer in targets:
		enemy.process_mode = Node.PROCESS_MODE_DISABLED
		enemy.global_position = Vector2(1120.0, 620.0)
	var target := targets[0]
	target.process_mode = Node.PROCESS_MODE_INHERIT
	target.global_position = player.global_position + Vector2(0.0, 88.0)
	target.health = 1.0
	target.resolve = 1.0
	target.move_speed = 0.0
	target.attack_damage = 0.0
	for _frame: int in 45:
		await physics_frame
		await process_frame
	_expect(scene.get_kills() == 0, "%s does not attack without player input" % HERO_NAMES[hero_index])
	var aim_motion := InputEventJoypadMotion.new()
	aim_motion.device = 0
	aim_motion.axis = JOY_AXIS_RIGHT_Y
	aim_motion.axis_value = 1.0
	Input.parse_input_event(aim_motion)
	await physics_frame
	await process_frame
	_expect(player.get(&"aim_direction").dot(Vector2.DOWN) > 0.90, "%s manual right-stick aim works in Survivor mode" % HERO_NAMES[hero_index])
	Input.action_press(&"primary")
	await physics_frame
	await process_frame
	Input.action_release(&"primary")
	for _frame: int in 120:
		await physics_frame
		await process_frame
		if scene.get_kills() > 0 and scene.get_experience() > 0:
			break
	_expect(scene.get_kills() == 1, "%s manual primary defeats its aimed target" % HERO_NAMES[hero_index])
	_expect(scene.get_experience() >= 1, "%s collects the defeated target's Essence shard" % HERO_NAMES[hero_index])
	aim_motion.axis_value = 0.0
	Input.parse_input_event(aim_motion)
	scene.queue_free()
	for _frame: int in 8:
		await process_frame
	return _failures.is_empty()


func _check_level_up() -> void:
	var scene = HERO_SCENES[0].instantiate()
	scene.set(&"audio_enabled", false)
	root.add_child(scene)
	for _frame: int in 8:
		await process_frame
	var player := scene.get_player() as Node2D
	scene.grant_test_experience(4)
	_expect(scene.get_run_level() == 2, "enough Essence advances the run level")
	_expect(scene.is_level_up_active() and paused, "level-up pauses the active horde")
	scene.choose_test_upgrade(&"signature", 1)
	_expect(not scene.is_level_up_active() and not paused, "choosing a boon resumes the run")
	_expect(scene.get_upgrade_rank(&"signature") == 1 and bool(player.call(&"is_survivor_ability_unlocked", &"signature")), "first host ability pick unlocks rank one on the hero")
	var scene_progression: SurvivorProgression = scene.get("_progression") as SurvivorProgression
	scene_progression.apply_pick(&"signature", 3)
	scene.call("_sync_ability_progression")
	scene.grant_test_experience(10)
	scene.choose_test_upgrade(&"signature", 1)
	var hero_announcement := scene.get_node(^"KatCombatHud").get("_announcement") as Label
	_expect(scene.get_upgrade_rank(&"signature") == 5 and hero_announcement.text.contains("EVOLVED / TIER 2"), "a skill crossing rank five announces its named evolution")
	scene.queue_free()
	for _frame: int in 8:
		await process_frame

	var controller_scene = HERO_SCENES[0].instantiate()
	controller_scene.set(&"audio_enabled", false)
	root.add_child(controller_scene)
	for _frame: int in 8:
		await process_frame
	controller_scene.grant_test_experience(4)
	var controller_hud := controller_scene.get_node(^"SurvivorRunHud") as SurvivorRunHud
	var controller_options: Array = controller_hud.get("_options")
	var focused_option: Dictionary = controller_options[0]
	var confirm_event := InputEventJoypadButton.new()
	confirm_event.device = 0
	confirm_event.button_index = JOY_BUTTON_A
	confirm_event.pressed = true
	Input.parse_input_event(confirm_event)
	await process_frame
	confirm_event.pressed = false
	Input.parse_input_event(confirm_event)
	_expect(not controller_scene.is_level_up_active() and not paused, "Xbox A confirms the focused level-up boon")
	_expect(controller_scene.get_upgrade_rank(StringName(focused_option[&"id"])) == int(focused_option.get(&"amount", 1)), "controller confirmation applies the focused boon amount")
	controller_scene.queue_free()
	for _frame: int in 8:
		await process_frame

	var stat_scene = HERO_SCENES[0].instantiate()
	stat_scene.set(&"audio_enabled", false)
	root.add_child(stat_scene)
	for _frame: int in 8:
		await process_frame
	var stat_player := stat_scene.get_player() as Node2D
	stat_scene.grant_test_experience(4)
	stat_scene.choose_test_upgrade(&"strength", 2)
	_expect(stat_scene.get_upgrade_rank(&"strength") == 2, "a double boon applies two upgrade ranks")
	_expect(is_equal_approx(float(stat_player.call(&"get_survivor_scaling_multiplier", &"strength")), 1.24), "Strength scales Strength attacks once per rank")
	_expect(is_equal_approx(float(stat_player.call(&"get_max_resolve")), KatPlayer.MAX_RESOLVE * 1.08), "Strength slightly increases maximum Resolve")
	stat_scene.queue_free()
	for _frame: int in 8:
		await process_frame

	var intelligence_scene = HERO_SCENES[0].instantiate()
	intelligence_scene.set(&"audio_enabled", false)
	root.add_child(intelligence_scene)
	for _frame: int in 8:
		await process_frame
	intelligence_scene.grant_test_experience(4)
	intelligence_scene.choose_test_upgrade(&"intelligence", 2)
	intelligence_scene.set("_experience", 0)
	intelligence_scene.set("_experience_required", 100)
	intelligence_scene.call(&"_on_experience_collected", 10)
	_expect(intelligence_scene.get_experience() == 11, "Intelligence slightly increases Arcane Essence gain")
	intelligence_scene.queue_free()
	for _frame: int in 8:
		await process_frame

	var basic_scene = HERO_SCENES[0].instantiate()
	basic_scene.set(&"audio_enabled", false)
	root.add_child(basic_scene)
	for _frame: int in 8:
		await process_frame
	basic_scene.set("_level", 4)
	basic_scene.set("_experience", 0)
	basic_scene.set("_experience_required", 1)
	var basic_progression: SurvivorProgression = basic_scene.get("_progression") as SurvivorProgression
	basic_progression.set_run_level(4)
	basic_scene.grant_test_experience(1)
	basic_scene.choose_test_upgrade(&"strength", 1)
	var basic_announcement := basic_scene.get_node(^"KatCombatHud").get("_announcement") as Label
	_expect(basic_scene.get_run_level() == 5 and basic_announcement.text.contains("BASIC ATTACK EVOLVED / TIER 2"), "run level five visibly announces the independent basic-attack evolution")
	basic_scene.queue_free()
	for _frame: int in 8:
		await process_frame


func _check_timed_victory() -> void:
	var scene = HERO_SCENES[0].instantiate()
	scene.set(&"audio_enabled", false)
	scene.set(&"run_duration", 0.05)
	root.add_child(scene)
	for _frame: int in 12:
		await physics_frame
		await process_frame
	_expect(scene.is_run_ended(), "reaching the run duration ends the ritual")
	var run_hud := scene.get_node(^"SurvivorRunHud") as SurvivorRunHud
	_expect(paused and run_hud.is_modal_open(), "timed victory pauses combat and opens the run summary")
	scene.queue_free()
	for _frame: int in 8:
		await process_frame


func _break_with_cleanup() -> void:
	paused = false
	for failure: String in _failures:
		push_error(failure)
	quit(1)


func _expect(condition: bool, message: String) -> void:
	_check_count += 1
	if not condition:
		_failures.append(message)