extends SceneTree


const HERO_SCENES := [
	preload("res://scenes/arena/kat_combat_slice.tscn"),
	preload("res://scenes/arena/sniff_combat_slice.tscn"),
	preload("res://scenes/arena/nad_combat_slice.tscn"),
	preload("res://scenes/arena/fin_combat_slice.tscn"),
]
const HERO_NAMES := ["Kat", "Sniff", "Nad", "Fin"]
const ProgressionScript := preload("res://scripts/survivors/survivor_progression.gd")

var _failures: Array[String] = []
var _check_count := 0


func _init() -> void:
	call_deferred(&"_run")


func _run() -> void:
	_check_progression_model()
	_check_arena_layout()
	await _check_tier_behavior_contracts()
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
	_expect(progression.get_rank(&"signature") == 0 and not progression.is_unlocked(&"signature"), "active abilities start locked")
	var first_pick: Dictionary = progression.apply_pick(&"signature")
	_expect(first_pick[&"rank"] == 1 and progression.is_unlocked(&"signature"), "first ability pick unlocks rank one")
	var second_pick: Dictionary = progression.apply_pick(&"signature")
	_expect(second_pick[&"rank"] == 2 and progression.get_ability_power_multiplier(&"signature") > 0.58, "repeat ability picks improve its rank and power")
	for milestone: Array in [[1, 1], [5, 2], [10, 3], [15, 4], [20, 5]]:
		progression.set_run_level(int(milestone[0]))
		_expect(progression.get_tier() == int(milestone[1]), "run level %d selects ability tier %d" % milestone)
	var sniff_options: Array[Dictionary] = progression.roll_options(rng, 11)
	var found_thunder_dash := false
	for option: Dictionary in sniff_options:
		if option[&"id"] == &"signature":
			found_thunder_dash = String(option[&"title"]) == "THUNDER DASH"
	_expect(found_thunder_dash, "hero ability choices use the selected hero's identity")


func _check_tier_behavior_contracts() -> void:
	var sniff_tier_one := SniffPlayer.new()
	root.add_child(sniff_tier_one)
	await process_frame
	sniff_tier_one.set_survivor_mode(true)
	sniff_tier_one.set_survivor_ability_progress(&"signature", 1, 1, 0.58, 1.32)
	sniff_tier_one.call(&"_begin_thunder_dash")
	_expect(not sniff_tier_one.is_dash_charging(), "tier-one Thunder Dash releases instantly without a charge state")
	sniff_tier_one.queue_free()
	await process_frame

	var sniff_tier_three := SniffPlayer.new()
	root.add_child(sniff_tier_three)
	await process_frame
	sniff_tier_three.set_survivor_mode(true)
	sniff_tier_three.set_survivor_ability_progress(&"signature", 1, 3, 1.0, 1.0)
	sniff_tier_three.call(&"_begin_thunder_dash")
	_expect(sniff_tier_three.is_dash_charging(), "tier-three Thunder Dash retains the original charge state")
	sniff_tier_three.queue_free()
	await process_frame

	var sniff_tier_five := SniffPlayer.new()
	root.add_child(sniff_tier_five)
	await process_frame
	sniff_tier_five.set_survivor_mode(true)
	sniff_tier_five.set_survivor_ability_progress(&"signature", 1, 5, 1.62, 0.74)
	sniff_tier_five.global_position = Vector2(200.0, 360.0)
	sniff_tier_five.aim_direction = Vector2.RIGHT
	var route_target := ReliquaryPursuer.new()
	route_target.configure(sniff_tier_five, 0)
	route_target.global_position = Vector2(350.0, 440.0)
	root.add_child(route_target)
	await process_frame
	route_target.process_mode = Node.PROCESS_MODE_DISABLED
	var route_target_health := route_target.health
	sniff_tier_five.call(&"_begin_thunder_dash")
	sniff_tier_five.set("_dash_charge", 1.0)
	sniff_tier_five.call(&"_release_thunder_dash")
	for _frame: int in 8:
		await physics_frame
		await process_frame
	_expect(route_target.health < route_target_health, "tier-five Thunder Dash detonates enemies beside the traversed route")
	route_target.queue_free()
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


func _check_hero_run(hero_index: int) -> bool:
	var scene = HERO_SCENES[hero_index].instantiate()
	scene.set(&"audio_enabled", false)
	root.add_child(scene)
	for _frame: int in 8:
		await process_frame
	var player := scene.get_player() as Node2D
	_expect(is_instance_valid(player) and player.name == HERO_NAMES[hero_index], "%s run creates the selected hero" % HERO_NAMES[hero_index])
	_expect(scene.get_enemy_count() >= 5, "%s run starts under horde pressure" % HERO_NAMES[hero_index])
	var active_slots_locked := true
	for slot: StringName in ProgressionScript.ABILITY_SLOTS:
		active_slots_locked = active_slots_locked and not bool(player.call(&"is_survivor_ability_unlocked", slot))
	_expect(active_slots_locked, "%s starts with only its automatic basic attack" % HERO_NAMES[hero_index])

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
	target.global_position = player.global_position + Vector2(88.0, 0.0)
	target.health = 1.0
	target.resolve = 1.0
	target.move_speed = 0.0
	target.attack_damage = 0.0
	for _frame: int in 120:
		await physics_frame
		await process_frame
		if scene.get_kills() > 0 and scene.get_experience() > 0:
			break
	_expect(scene.get_kills() == 1, "%s automatic primary defeats its nearest target" % HERO_NAMES[hero_index])
	_expect(scene.get_experience() >= 1, "%s collects the defeated target's Essence shard" % HERO_NAMES[hero_index])
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
	scene.choose_test_upgrade(&"signature")
	_expect(not scene.is_level_up_active() and not paused, "choosing a boon resumes the run")
	_expect(scene.get_upgrade_rank(&"signature") == 1 and bool(player.call(&"is_survivor_ability_unlocked", &"signature")), "first host ability pick unlocks rank one on the hero")
	scene.queue_free()
	for _frame: int in 8:
		await process_frame

	var stat_scene = HERO_SCENES[0].instantiate()
	stat_scene.set(&"audio_enabled", false)
	root.add_child(stat_scene)
	for _frame: int in 8:
		await process_frame
	var stat_player := stat_scene.get_player() as Node2D
	stat_scene.grant_test_experience(4)
	stat_scene.choose_test_upgrade(&"force")
	_expect(is_equal_approx(float(stat_player.call(&"get_survivor_power_multiplier")), 1.12), "Force applies the run power multiplier")
	stat_scene.queue_free()
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