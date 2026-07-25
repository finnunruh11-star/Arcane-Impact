class_name SurvivorRun
extends Node2D


const SurvivorRunHudScript := preload("res://scripts/survivors/survivor_run_hud.gd")
const ExperienceShardScript := preload("res://scripts/survivors/survivor_experience_shard.gd")
const ProgressionScript := preload("res://scripts/survivors/survivor_progression.gd")
const HERO_SCRIPTS := [
	preload("res://scripts/characters/kat/kat_player.gd"),
	preload("res://scripts/characters/sniff/sniff_player.gd"),
	preload("res://scripts/characters/nad/nad_player.gd"),
	preload("res://scripts/characters/fin/fin_player.gd"),
]
const HUD_SCRIPTS := [
	preload("res://scripts/ui/kat_combat_hud.gd"),
	preload("res://scripts/ui/sniff_combat_hud.gd"),
	preload("res://scripts/ui/nad_combat_hud.gd"),
	preload("res://scripts/ui/fin_combat_hud.gd"),
]
const HERO_NAMES := ["Kat", "Sniff", "Nad", "Fin"]
const HERO_INTROS := ["THE TITHE BEGINS", "THE STORM GATHERS", "THE MIND OPENS", "THE HUNT BEGINS"]
const RUN_DURATION := 600.0
const STARTING_ENEMIES := 5
const MAX_ENEMIES := 48
const BASE_PICKUP_RADIUS := 120.0

@export_range(0, 3, 1) var hero_index := 0
@export var audio_enabled := true
@export var run_duration := RUN_DURATION

var _world: Node2D
var _player: Node2D
var _camera: CameraTrauma
var _impact_director: ImpactDirector
var _hero_hud: CanvasLayer
var _run_hud: CanvasLayer
var _shield_effect: PixelSheetEffect
var _progression
var _enemies: Array[ReliquaryPursuer] = []
var _rng := RandomNumberGenerator.new()
var _run_time := 0.0
var _spawn_timer := 0.0
var _recovery_timer := 0.0
var _kills := 0
var _level := 1
var _experience := 0
var _experience_required := 4
var _experience_multiplier := 1.0
var _pending_upgrade_values: Dictionary = {}
var _level_up_active := false
var _run_ended := false


func _enter_tree() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	InputProfile.ensure_default_bindings()


func _ready() -> void:
	hero_index = clampi(hero_index, 0, HERO_SCRIPTS.size() - 1)
	_rng.randomize()
	_progression = ProgressionScript.new()
	_progression.configure(hero_index)
	_build_world()
	_build_presentation()
	_build_player_and_huds()
	for _enemy_index: int in STARTING_ENEMIES:
		_spawn_enemy()
	_update_huds()
	_hero_hud.call(&"announce", HERO_INTROS[hero_index])
	print("Arcane Impact Survivors run ready for %s." % HERO_NAMES[hero_index])


func _exit_tree() -> void:
	if is_instance_valid(get_tree()):
		get_tree().paused = false


func _process(delta: float) -> void:
	if Input.is_action_just_pressed(&"pause"):
		_return_to_roster()
		return
	if Input.is_action_just_pressed(&"toggle_debug") and is_instance_valid(_player):
		_player.set(&"debug_draw_enabled", not bool(_player.get(&"debug_draw_enabled")))
		_player.queue_redraw()
	if _run_ended or _level_up_active or get_tree().paused:
		return
	if not is_instance_valid(_player) or not bool(_player.call(&"is_alive")):
		return
	_run_time = minf(run_duration, _run_time + delta)
	_refresh_enemies()
	_tick_spawner(delta)
	_tick_recovery(delta)
	_update_huds()
	if _run_time >= run_duration:
		_finish_run(true)


func get_player() -> Node2D:
	return _player


func get_run_level() -> int:
	return _level


func get_experience() -> int:
	return _experience


func get_kills() -> int:
	return _kills


func get_enemy_count() -> int:
	_refresh_enemies()
	return _enemies.size()


func is_level_up_active() -> bool:
	return _level_up_active


func is_run_ended() -> bool:
	return _run_ended


func grant_test_experience(amount: int) -> void:
	_grant_experience(amount)


func choose_test_upgrade(upgrade_id: StringName, amount := 0) -> void:
	if _level_up_active:
		_on_upgrade_selected(upgrade_id, amount)


func get_upgrade_rank(upgrade_id: StringName) -> int:
	return _progression.get_rank(upgrade_id) if _progression != null else 0


func get_ability_tier() -> int:
	return _progression.get_tier() if _progression != null else 1


func _build_world() -> void:
	_world = Node2D.new()
	_world.name = "CombatWorld"
	_world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_world)
	var arena := ArenaBackdrop.new()
	arena.name = "ShatteredReliquary"
	_world.add_child(arena)


func _build_presentation() -> void:
	_camera = CameraTrauma.new()
	_camera.name = "CameraTrauma"
	add_child(_camera)
	var hit_stop := HitStop.new()
	hit_stop.name = "HitStop"
	add_child(hit_stop)
	_impact_director = ImpactDirector.new()
	_impact_director.name = "ImpactDirector"
	_impact_director.configure(_camera, hit_stop)
	add_child(_impact_director)


func _build_player_and_huds() -> void:
	var player_script: Script = HERO_SCRIPTS[hero_index]
	_player = player_script.new() as Node2D
	_player.name = HERO_NAMES[hero_index]
	_player.global_position = Vector2(640.0, 360.0)
	_player.call(&"set_survivor_mode", true)
	_player.call(&"set_survivor_power_multiplier", 1.0)
	_sync_ability_progression()
	if _player.has_method(&"set_movement_bounds"):
		_player.call(&"set_movement_bounds", ArenaBackdrop.PLAYABLE_RECT.grow(-36.0))
	_world.add_child(_player)
	_camera.configure_follow(_player, ArenaBackdrop.PLAYABLE_RECT)
	_connect_player_presentation()

	var hud_script: Script = HUD_SCRIPTS[hero_index]
	_hero_hud = hud_script.new() as CanvasLayer
	_hero_hud.name = "%sCombatHud" % HERO_NAMES[hero_index]
	_hero_hud.call(&"configure", _player)
	add_child(_hero_hud)
	_player.connect(&"announcement_requested", Callable(_hero_hud, &"announce"))

	_run_hud = SurvivorRunHudScript.new() as CanvasLayer
	_run_hud.name = "SurvivorRunHud"
	_run_hud.call(&"configure", HERO_NAMES[hero_index].to_upper())
	add_child(_run_hud)
	_run_hud.connect(&"upgrade_selected", Callable(self, &"_on_upgrade_selected"))
	_run_hud.connect(&"retry_requested", Callable(self, &"_retry_run"))
	_run_hud.connect(&"roster_requested", Callable(self, &"_return_to_roster"))


func _connect_player_presentation() -> void:
	_player.connect(&"effect_requested", Callable(_impact_director, &"play_effect"))
	if audio_enabled:
		_player.connect(&"audio_requested", Callable(_impact_director, &"play_audio"))
	_player.connect(&"defeated", Callable(self, &"_on_player_defeated"))
	match hero_index:
		0:
			_player.connect(&"combat_impact", Callable(_impact_director, &"kat_combat_impact"))
			_player.connect(&"guard_impact", Callable(_impact_director, &"play_guard_impact"))
			_player.connect(&"shield_visual_changed", Callable(self, &"_on_shield_visual_changed"))
		1:
			_player.connect(&"combat_impact", Callable(_impact_director, &"sniff_combat_impact"))
			_player.connect(&"lightning_arc_requested", Callable(_impact_director, &"play_lightning_arc"))
			_player.connect(&"thunder_burst_requested", Callable(_impact_director, &"play_thunder_burst"))
		2:
			_player.connect(&"combat_impact", Callable(_impact_director, &"nad_combat_impact"))
			_player.connect(&"mind_link_requested", Callable(_impact_director, &"play_mind_link"))
			_player.connect(&"distortion_requested", Callable(_impact_director, &"play_mental_distortion"))
		3:
			_player.connect(&"combat_impact", Callable(_impact_director, &"fin_combat_impact"))


func _refresh_enemies() -> void:
	_enemies = _enemies.filter(func(enemy: ReliquaryPursuer) -> bool:
		return is_instance_valid(enemy) and enemy.is_alive()
	)


func _tick_spawner(delta: float) -> void:
	_spawn_timer -= delta
	var target_count := mini(MAX_ENEMIES, 6 + int(floor(_run_time / 12.0)) * 2)
	if _spawn_timer > 0.0 or _enemies.size() >= target_count:
		return
	_spawn_enemy()
	_spawn_timer = maxf(0.20, 0.86 - _run_time * 0.0011)


func _spawn_enemy() -> void:
	if not is_instance_valid(_player):
		return
	var enemy := ReliquaryPursuer.new()
	var variant := (_kills + _enemies.size()) % 3
	enemy.configure(_player, variant)
	var health_scale := 1.0 + _run_time / 210.0
	var damage_scale := 1.0 + _run_time / 360.0
	var speed_scale := 1.0 + minf(0.18, _run_time / 2400.0)
	enemy.max_health *= health_scale
	enemy.health = enemy.max_health
	enemy.max_resolve *= health_scale
	enemy.resolve = enemy.max_resolve
	enemy.attack_damage *= damage_scale
	enemy.move_speed *= speed_scale
	enemy.global_position = _random_edge_position()
	_world.add_child(enemy)
	enemy.attack_connected.connect(_impact_director.enemy_attack_impact)
	enemy.effect_requested.connect(_impact_director.play_effect)
	if audio_enabled:
		enemy.audio_requested.connect(_impact_director.play_audio)
	enemy.defeated.connect(_on_enemy_defeated)
	_enemies.append(enemy)


func _random_edge_position() -> Vector2:
	var bounds := ArenaBackdrop.PLAYABLE_RECT.grow(-42.0)
	for _attempt: int in 12:
		var side := _rng.randi_range(0, 3)
		var candidate: Vector2
		match side:
			0:
				candidate = Vector2(_rng.randf_range(bounds.position.x, bounds.end.x), bounds.position.y)
			1:
				candidate = Vector2(bounds.end.x, _rng.randf_range(bounds.position.y, bounds.end.y))
			2:
				candidate = Vector2(_rng.randf_range(bounds.position.x, bounds.end.x), bounds.end.y)
			_:
				candidate = Vector2(bounds.position.x, _rng.randf_range(bounds.position.y, bounds.end.y))
		if ArenaBackdrop.is_position_clear(candidate, 54.0):
			return candidate
	return bounds.position


func _tick_recovery(delta: float) -> void:
	if not _player.has_method(&"get_survivor_health_regen"):
		return
	var recovery_per_second := float(_player.call(&"get_survivor_health_regen"))
	if recovery_per_second <= 0.0:
		return
	_recovery_timer += delta
	if _recovery_timer < 1.0:
		return
	var elapsed_ticks := floori(_recovery_timer)
	_recovery_timer -= float(elapsed_ticks)
	_player.call(&"heal", recovery_per_second * float(elapsed_ticks))


func _on_enemy_defeated(enemy: ReliquaryPursuer) -> void:
	_kills += 1
	var shard = ExperienceShardScript.new()
	shard.name = "ArcaneEssence"
	shard.configure(_player, 1 + int(floor(_run_time / 180.0)), BASE_PICKUP_RADIUS)
	shard.global_position = enemy.global_position
	shard.add_to_group(&"survivor_pickups")
	shard.collected.connect(_on_experience_collected)
	_world.add_child(shard)
	_update_huds()


func _on_experience_collected(value: int) -> void:
	_grant_experience(maxi(1, roundi(float(value) * _experience_multiplier)))


func _grant_experience(amount: int) -> void:
	_experience += maxi(0, amount)
	_try_level_up()
	_update_huds()


func _try_level_up() -> void:
	if _level_up_active or _run_ended or _experience < _experience_required:
		return
	_experience -= _experience_required
	_level += 1
	_experience_required = 4 + _level * 3
	_progression.set_run_level(_level)
	_sync_ability_progression()
	_level_up_active = true
	get_tree().paused = true
	_run_hud.call(&"show_level_up", _roll_upgrade_options())


func _roll_upgrade_options() -> Array[Dictionary]:
	var options: Array[Dictionary] = _progression.roll_options(_rng, 6)
	_pending_upgrade_values.clear()
	for option: Dictionary in options:
		_pending_upgrade_values[option[&"id"]] = int(option.get(&"amount", 1))
	return options


func _on_upgrade_selected(upgrade_id: StringName, forced_amount := 0) -> void:
	if not _level_up_active:
		return
	var amount := forced_amount if forced_amount > 0 else int(_pending_upgrade_values.get(upgrade_id, 1))
	var state: Dictionary = _progression.apply_pick(upgrade_id, amount)
	if state[&"kind"] == &"ability":
		_sync_ability_progression()
	elif _player.has_method(&"apply_survivor_stat"):
		_player.call(&"apply_survivor_stat", upgrade_id, amount)
	match upgrade_id:
		&"intelligence":
			_experience_multiplier += 0.05 * float(amount)
	_pending_upgrade_values.clear()
	_level_up_active = false
	_run_hud.call(&"hide_modal")
	_run_hud.call(&"set_upgrade_summary", _progression.get_summary())
	get_tree().paused = false
	var announcement := "UNLOCKED" if state[&"kind"] == &"ability" and int(state[&"rank"]) <= amount else String(upgrade_id).to_upper()
	_hero_hud.call(&"announce", "DOUBLE %s" % announcement if amount > 1 else announcement)
	call_deferred(&"_try_level_up")


func _sync_ability_progression() -> void:
	if not is_instance_valid(_player) or not _player.has_method(&"set_survivor_ability_progress"):
		return
	for slot: StringName in ProgressionScript.ABILITY_SLOTS:
		_player.call(
			&"set_survivor_ability_progress",
			slot,
			_progression.get_rank(slot),
			_progression.get_tier(),
			_progression.get_ability_power_multiplier(slot),
			_progression.get_ability_cooldown_multiplier(slot)
		)


func _update_huds() -> void:
	if not is_instance_valid(_run_hud) or not is_instance_valid(_hero_hud):
		return
	_run_hud.call(&"set_run_state", _run_time, _level, _experience, _experience_required, _kills, _enemies.size())
	_hero_hud.call(&"set_survivor_encounter", _level, _enemies.size())


func _on_player_defeated() -> void:
	_on_shield_visual_changed(false)
	_finish_run(false)


func _finish_run(victory: bool) -> void:
	if _run_ended:
		return
	_run_ended = true
	get_tree().paused = true
	_run_hud.call(&"show_run_end", victory, _run_time, _kills, _level)


func _retry_run() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _return_to_roster() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/roster_select.tscn")


func _on_shield_visual_changed(active: bool) -> void:
	if is_instance_valid(_shield_effect):
		_shield_effect.finish()
		_shield_effect = null
	if active and is_instance_valid(_player):
		_shield_effect = VfxCatalog.spawn_attached(_player, &"kat_absorb", Vector2.ZERO, 1.18, Color(0.92, 0.72, 1.0, 0.74), true)
		_shield_effect.z_index = -1