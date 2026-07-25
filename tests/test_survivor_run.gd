extends SceneTree


const HERO_SCENES := [
	preload("res://scenes/arena/kat_combat_slice.tscn"),
	preload("res://scenes/arena/sniff_combat_slice.tscn"),
	preload("res://scenes/arena/nad_combat_slice.tscn"),
	preload("res://scenes/arena/fin_combat_slice.tscn"),
]
const HERO_NAMES := ["Kat", "Sniff", "Nad", "Fin"]

var _failures: Array[String] = []
var _check_count := 0


func _init() -> void:
	call_deferred(&"_run")


func _run() -> void:
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


func _check_hero_run(hero_index: int) -> bool:
	var scene = HERO_SCENES[hero_index].instantiate()
	scene.set(&"audio_enabled", false)
	root.add_child(scene)
	for _frame: int in 8:
		await process_frame
	var player := scene.get_player() as Node2D
	_expect(is_instance_valid(player) and player.name == HERO_NAMES[hero_index], "%s run creates the selected hero" % HERO_NAMES[hero_index])
	_expect(scene.get_enemy_count() >= 5, "%s run starts under horde pressure" % HERO_NAMES[hero_index])

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
	scene.choose_test_upgrade(&"force")
	_expect(not scene.is_level_up_active() and not paused, "choosing a boon resumes the run")
	_expect(is_equal_approx(float(player.call(&"get_survivor_power_multiplier")), 1.2), "Force applies the run power multiplier")
	scene.queue_free()
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