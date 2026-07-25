class_name SniffPlayer
extends CharacterBody2D


const SurvivorAbilityStateScript := preload("res://scripts/survivors/survivor_ability_state.gd")
const SurvivorStatStateScript := preload("res://scripts/survivors/survivor_stat_state.gd")

signal combat_impact(at: Vector2, direction: Vector2, packet: DamagePacket, intensity: float)
signal effect_requested(effect_id: StringName, at: Vector2, direction: Vector2, size_scale: float)
signal audio_requested(cue: StringName, power: float)
signal lightning_arc_requested(from: Vector2, to: Vector2, power: float)
signal thunder_burst_requested(at: Vector2, radius: float, power: float, ultimate: bool)
signal stats_changed
signal state_changed(label: String)
signal announcement_requested(text: String)
signal defeated

enum State {
	FREE,
	DART_STARTUP,
	DART_RECOVERY,
	WAYWARD_DASH,
	WAYWARD_RECOVERY,
	TEMPEST_STARTUP,
	TEMPEST_RECOVERY,
	DISCHARGE_STARTUP,
	DISCHARGE_RECOVERY,
	FLASHSTEP,
	FLASHSTEP_RECOVERY,
	WORLDSTORM_STARTUP,
	WORLDSTORM_RECOVERY,
	STAGGER,
	DEAD,
}

const MAX_HEALTH := 245.0
const MAX_RESOLVE := 138.0
const MAX_MANA := 130.0
const MAX_VOLTAIC_LOAD := 10
const MAX_BLESSING := MAX_VOLTAIC_LOAD
const MOVE_SPEED := 332.0
const BASE_MANA_REGEN := 8.5
const DART_MANA_COST := 6.0
const WAYWARD_BOLT_MANA_COST := 72.0
const TEMPEST_MANA_COST := 76.0
const DISCHARGE_MANA_COST := 84.0
const FLASHSTEP_MANA_COST := 16.0
const WORLDSTORM_MANA_COST := 96.0
const INPUT_BUFFER_DURATION := 0.12
const MAX_ABILITY_CHARGES := 2
const WAYWARD_BOLT_COOLDOWN := 8.0
const TEMPEST_COOLDOWN := 12.0
const DISCHARGE_COOLDOWN := 14.0
const FLASHSTEP_COOLDOWN := 0.75
const WORLDSTORM_COOLDOWN := 28.0
const TEMPEST_BASE_RADIUS := 520.0
const DISCHARGE_BASE_RADIUS := 390.0
const DISCHARGE_STACK_RADIUS := 52.0
const WORLDSTORM_BASE_RADIUS := 1050.0
const LOAD_MOVE_SPEED_PER_STACK := 0.025
const LOAD_POWER_PER_STACK := 0.055
const OVERLOAD_THRESHOLD := 7
const OVERLOAD_TICK_INTERVAL := 0.80
const OVERLOAD_BASE_DAMAGE := 2.0
const OVERLOAD_DAMAGE_PER_EXCESS_STACK := 1.25

var health := MAX_HEALTH
var resolve := MAX_RESOLVE
var mana := MAX_MANA
var blessing := 0
var aim_direction := Vector2.RIGHT
var debug_draw_enabled := false
var chain_chance := 0.30

var wayward_cooldown := 0.0
var blessing_cooldown := 0.0
var surge_cooldown := 0.0
var flashstep_cooldown := 0.0
var ultimate_cooldown := 0.0
var wayward_charges := MAX_ABILITY_CHARGES
var blessing_charges := MAX_ABILITY_CHARGES
var surge_charges := MAX_ABILITY_CHARGES
var flashstep_charges := MAX_ABILITY_CHARGES
var ultimate_charges := MAX_ABILITY_CHARGES

var _state := State.FREE
var _state_time := 0.0
var _using_gamepad := false
var _primary_buffer := 0.0
var _dash_direction := Vector2.RIGHT
var _dash_speed := 0.0
var _spell_center := Vector2.ZERO
var _spell_radius := TEMPEST_BASE_RADIUS
var _spell_load_snapshot := 0
var _wayward_segments_remaining := 0
var _wayward_segment_duration := 0.08
var _wayward_segment_time := 0.0
var _wayward_hit_count := 0
var _wayward_direction_changes := 0
var _wayward_path := PackedVector2Array()
var _backfire_override := -1
var _last_spell_backfired := false
var _invulnerable_time := 0.0
var _overload_tick_remaining := OVERLOAD_TICK_INTERVAL
var _knockback_velocity := Vector2.ZERO
var _hit_target_ids: Dictionary = {}
var _attack_area: Area2D
var _attack_shape: CollisionShape2D
var _visual_time := 0.0
var _rng := RandomNumberGenerator.new()
var _movement_bounds := Rect2()
var _has_movement_bounds := false
var _survivor_mode := false
var _survivor_target: Node2D
var _survivor_power_multiplier := 1.0
var _survivor_abilities = SurvivorAbilityStateScript.new()
var _survivor_stats = SurvivorStatStateScript.new()


func _ready() -> void:
	InputProfile.ensure_default_bindings()
	add_to_group(&"player")
	collision_layer = 1
	collision_mask = 2 | 4
	z_index = 12
	_rng.randomize()

	var body_shape := CollisionShape2D.new()
	var body_circle := CircleShape2D.new()
	body_circle.radius = 27.0
	body_shape.shape = body_circle
	body_shape.position = Vector2(0.0, 4.0)
	add_child(body_shape)

	var hurtbox := Area2D.new()
	hurtbox.name = "Hurtbox"
	hurtbox.collision_layer = 64
	hurtbox.collision_mask = 0
	hurtbox.monitorable = true
	hurtbox.monitoring = false
	add_child(hurtbox)
	var hurt_shape := CollisionShape2D.new()
	var hurt_circle := CircleShape2D.new()
	hurt_circle.radius = 32.0
	hurt_shape.shape = hurt_circle
	hurt_shape.position = Vector2(0.0, 4.0)
	hurtbox.add_child(hurt_shape)

	_attack_area = Area2D.new()
	_attack_area.name = "SniffAttackArea"
	_attack_area.collision_layer = 8
	_attack_area.collision_mask = 16
	_attack_area.monitoring = false
	_attack_area.monitorable = false
	add_child(_attack_area)
	_attack_shape = CollisionShape2D.new()
	var attack_circle := CircleShape2D.new()
	attack_circle.radius = 46.0
	_attack_shape.shape = attack_circle
	_attack_area.add_child(_attack_shape)
	stats_changed.emit()
	queue_redraw()


func set_survivor_mode(enabled: bool) -> void:
	_survivor_mode = enabled
	if not enabled:
		_survivor_target = null


func set_survivor_power_multiplier(multiplier: float) -> void:
	_survivor_power_multiplier = maxf(0.1, multiplier)


func get_survivor_power_multiplier() -> float:
	return _survivor_power_multiplier * get_voltaic_power_multiplier()


func set_survivor_basic_attack_progress(tier: int, power: float) -> void:
	_survivor_abilities.set_basic_attack_progress(tier, power)


func get_survivor_basic_attack_tier() -> int:
	return _survivor_abilities.get_basic_attack_tier() if _survivor_mode else 3


func set_survivor_ability_progress(slot: StringName, rank: int, tier: int, power: float, cooldown: float) -> void:
	_survivor_abilities.set_progress(slot, rank, tier, power, cooldown)


func is_survivor_ability_unlocked(slot: StringName) -> bool:
	return not _survivor_mode or _survivor_abilities.is_unlocked(slot)


func get_survivor_ability_rank(slot: StringName) -> int:
	return _survivor_abilities.get_rank(slot)


func get_survivor_ability_tier(slot: StringName) -> int:
	return _survivor_abilities.get_tier(slot) if _survivor_mode else 3


func get_survivor_ability_power_multiplier(slot: StringName) -> float:
	if slot == &"primary":
		return _survivor_abilities.get_basic_attack_power() if _survivor_mode else 1.0
	return _survivor_abilities.get_power(slot) if _survivor_mode else 1.0


func apply_survivor_stat(stat: StringName, amount: int) -> void:
	var previous_health := get_max_health()
	var previous_resolve := get_max_resolve()
	var previous_mana := get_max_mana()
	_survivor_stats.add_rank(stat, amount)
	health += get_max_health() - previous_health
	resolve += get_max_resolve() - previous_resolve
	mana += get_max_mana() - previous_mana
	stats_changed.emit()


func get_survivor_stat_rank(stat: StringName) -> int:
	return _survivor_stats.get_rank(stat)


func get_survivor_scaling_multiplier(scaling: StringName) -> float:
	return _survivor_stats.get_scaling_multiplier(scaling)


func get_survivor_critical_chance() -> float:
	return _survivor_stats.get_critical_chance()


func get_survivor_critical_damage() -> float:
	return _survivor_stats.get_critical_damage()


func roll_survivor_critical() -> bool:
	return _rng.randf() < get_survivor_critical_chance()


func get_max_health() -> float:
	return MAX_HEALTH * _survivor_stats.get_health_multiplier()


func get_max_resolve() -> float:
	return MAX_RESOLVE * _survivor_stats.get_resolve_multiplier()


func get_max_mana() -> float:
	return MAX_MANA * _survivor_stats.get_mana_multiplier()


func get_mana_regen_per_second() -> float:
	return BASE_MANA_REGEN * _survivor_stats.get_mana_regen_multiplier()


func get_move_speed() -> float:
	return MOVE_SPEED * _survivor_stats.get_move_speed_multiplier() * get_voltaic_move_speed_multiplier()


func is_voltaic_load_unlocked() -> bool:
	return not _survivor_mode or _survivor_abilities.is_unlocked(&"ability_1")


func get_voltaic_power_multiplier() -> float:
	return 1.0 + float(blessing) * LOAD_POWER_PER_STACK if is_voltaic_load_unlocked() else 1.0


func get_voltaic_move_speed_multiplier() -> float:
	return 1.0 + float(blessing) * LOAD_MOVE_SPEED_PER_STACK if is_voltaic_load_unlocked() else 1.0


func get_survivor_health_regen() -> float:
	return _survivor_stats.get_health_regen()


func _survivor_cooldown_delta(delta: float, slot: StringName) -> float:
	if not _survivor_mode:
		return delta
	if not _survivor_abilities.is_unlocked(slot):
		return 0.0
	return delta / _survivor_abilities.get_cooldown(slot)


func set_movement_bounds(bounds: Rect2) -> void:
	_movement_bounds = bounds.abs()
	_has_movement_bounds = _movement_bounds.has_area()


func clear_movement_bounds() -> void:
	_has_movement_bounds = false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		_set_using_gamepad(false)
	elif event is InputEventJoypadMotion:
		var motion := event as InputEventJoypadMotion
		if absf(motion.axis_value) > 0.24:
			_set_using_gamepad(true)
	elif event is InputEventJoypadButton and event.pressed:
		_set_using_gamepad(true)


func _physics_process(delta: float) -> void:
	_tick_timers(delta)
	_update_aim()
	_update_buffers(delta)
	_update_state(delta)
	_update_movement()
	move_and_slide()
	_clamp_to_movement_bounds()
	_visual_time += delta
	queue_redraw()


func _tick_timers(delta: float) -> void:
	_tick_ability_recharge(delta, &"signature")
	_tick_ability_recharge(delta, &"ability_1")
	_tick_ability_recharge(delta, &"ability_2")
	_tick_ability_recharge(delta, &"evade")
	_tick_ability_recharge(delta, &"ultimate")
	_invulnerable_time = maxf(0.0, _invulnerable_time - delta)
	resolve = minf(get_max_resolve(), resolve + delta * 6.5)
	mana = minf(get_max_mana(), mana + get_mana_regen_per_second() * delta)
	_tick_voltaic_overload(delta)


func _tick_voltaic_overload(delta: float) -> void:
	if not is_voltaic_load_unlocked() or blessing < OVERLOAD_THRESHOLD or _state == State.DEAD:
		_overload_tick_remaining = OVERLOAD_TICK_INTERVAL
		return
	_overload_tick_remaining -= delta
	if _overload_tick_remaining > 0.0:
		return
	_overload_tick_remaining += OVERLOAD_TICK_INTERVAL
	var excess_stacks := blessing - OVERLOAD_THRESHOLD
	var feedback_damage := OVERLOAD_BASE_DAMAGE + float(excess_stacks) * OVERLOAD_DAMAGE_PER_EXCESS_STACK
	_apply_storm_feedback(feedback_damage, false)


func _update_buffers(delta: float) -> void:
	_primary_buffer = maxf(0.0, _primary_buffer - delta)
	if _state != State.FREE and Input.is_action_just_pressed(&"primary"):
		_primary_buffer = INPUT_BUFFER_DURATION


func _update_aim() -> void:
	if _survivor_mode:
		if is_instance_valid(_survivor_target):
			var target_direction := _survivor_target.global_position - global_position
			if not target_direction.is_zero_approx():
				aim_direction = target_direction.normalized()
			return
	var raw_stick := Vector2(
		Input.get_joy_axis(0, JOY_AXIS_RIGHT_X),
		Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
	)
	var stick := CombatMath.apply_radial_deadzone(raw_stick, 0.18)
	if not stick.is_zero_approx():
		aim_direction = stick.normalized()
		_set_using_gamepad(true)
		return
	if not _using_gamepad:
		var mouse_direction := get_global_mouse_position() - global_position
		if mouse_direction.length_squared() > 100.0:
			aim_direction = mouse_direction.normalized()


func _update_state(delta: float) -> void:
	match _state:
		State.FREE:
			_handle_free_inputs()
		State.DART_STARTUP:
			_state_time -= delta
			if _state_time <= 0.0:
				_spawn_dart()
		State.DART_RECOVERY, State.WAYWARD_RECOVERY, State.TEMPEST_RECOVERY, State.DISCHARGE_RECOVERY, State.FLASHSTEP_RECOVERY, State.WORLDSTORM_RECOVERY, State.STAGGER:
			_state_time -= delta
			if _state_time <= 0.0:
				if _primary_buffer > 0.0 and _state != State.STAGGER:
					_primary_buffer = 0.0
					_begin_dart()
				else:
					_set_state(State.FREE)
		State.WAYWARD_DASH:
			_tick_wayward_bolt(delta)
		State.TEMPEST_STARTUP:
			_state_time -= delta
			if _state_time <= 0.0:
				_resolve_tempest_covenant()
		State.DISCHARGE_STARTUP:
			_state_time -= delta
			if _state_time <= 0.0:
				_resolve_cataclysm_discharge()
		State.FLASHSTEP:
			_apply_flashstep_hits()
			_state_time -= delta
			if _state_time <= 0.0:
				_attack_area.monitoring = false
				_set_enemy_phasing(false)
				if get_survivor_ability_tier(&"evade") >= 4:
					_resolve_flashstep_arrival()
				_state_time = 0.09
				_set_state(State.FLASHSTEP_RECOVERY)
		State.WORLDSTORM_STARTUP:
			_state_time -= delta
			if _state_time <= 0.0:
				_resolve_worldstorm()
		State.DEAD:
			pass


func _handle_free_inputs() -> void:
	if Input.is_action_just_pressed(&"ultimate") and is_survivor_ability_unlocked(&"ultimate") and has_ability_charge(&"ultimate"):
		_begin_worldstorm()
	elif Input.is_action_just_pressed(&"ability_1") and is_survivor_ability_unlocked(&"ability_1") and has_ability_charge(&"ability_1"):
		_begin_tempest_covenant()
	elif Input.is_action_just_pressed(&"ability_2") and is_survivor_ability_unlocked(&"ability_2") and has_ability_charge(&"ability_2"):
		_begin_cataclysm_discharge()
	elif Input.is_action_just_pressed(&"evade") and is_survivor_ability_unlocked(&"evade") and has_ability_charge(&"evade"):
		_begin_flashstep()
	elif Input.is_action_just_pressed(&"signature") and is_survivor_ability_unlocked(&"signature") and has_ability_charge(&"signature"):
		_begin_wayward_bolt()
	elif Input.is_action_just_pressed(&"primary") or _primary_buffer > 0.0:
		_primary_buffer = 0.0
		_begin_dart()


func try_survivor_primary(target: Node2D) -> bool:
	if not is_instance_valid(target):
		return false
	_survivor_target = target
	if _state != State.FREE:
		return false
	var target_direction := target.global_position - global_position
	if target_direction.is_zero_approx():
		return false
	aim_direction = target_direction.normalized()
	_primary_buffer = 0.0
	return _begin_dart()


func _update_movement() -> void:
	var move_input := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	var speed_scale := 1.0
	match _state:
		State.DART_STARTUP:
			speed_scale = 0.72
		State.DART_RECOVERY:
			speed_scale = 0.88
		State.WAYWARD_DASH, State.FLASHSTEP:
			velocity = _dash_direction * _dash_speed
			return
		State.TEMPEST_STARTUP:
			speed_scale = 0.24
		State.DISCHARGE_STARTUP:
			speed_scale = 0.12
		State.WAYWARD_RECOVERY, State.TEMPEST_RECOVERY, State.DISCHARGE_RECOVERY, State.FLASHSTEP_RECOVERY:
			speed_scale = 0.72
		State.WORLDSTORM_STARTUP:
			speed_scale = 0.08
		State.WORLDSTORM_RECOVERY:
			speed_scale = 0.46
		State.STAGGER, State.DEAD:
			speed_scale = 0.0
	velocity = move_input * get_move_speed() * speed_scale + _knockback_velocity
	_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, 42.0)


func _begin_dart() -> bool:
	if not _spend_mana(DART_MANA_COST):
		return false
	_state_time = [0.055, 0.050, 0.044, 0.038, 0.032][get_survivor_basic_attack_tier() - 1] as float
	audio_requested.emit(&"sniff_dart_charge", float(blessing) / float(MAX_BLESSING))
	_set_state(State.DART_STARTUP)
	return true


func _spawn_dart() -> void:
	var dart := SniffLightningDart.new()
	dart.configure(self, aim_direction, blessing)
	get_parent().add_child(dart)
	dart.global_position = global_position + aim_direction * 42.0
	var tier := get_survivor_basic_attack_tier()
	lightning_arc_requested.emit(global_position - aim_direction * 18.0, dart.global_position + aim_direction * 22.0, 0.30 + 0.10 * float(tier))
	audio_requested.emit(&"sniff_dart", float(blessing) / float(MAX_BLESSING))
	_state_time = [0.105, 0.094, 0.082, 0.070, 0.058][tier - 1] as float
	_set_state(State.DART_RECOVERY)


func on_lightning_dart_hit(target: Node2D, at: Vector2, direction: Vector2, blessing_snapshot: int) -> void:
	if not is_instance_valid(target) or not target.is_in_group(&"enemies"):
		return
	var packet := DamagePacket.sniff_dart(self, blessing_snapshot)
	var dealt := DamageResolver.apply_with_result(target, packet, direction)
	if dealt <= 0.0:
		return
	effect_requested.emit(&"sniff_strike", at, direction, 0.82)
	combat_impact.emit(at, direction, packet, 0.34 + float(blessing_snapshot) * 0.025)
	lightning_arc_requested.emit(at - direction * 48.0, at, 0.48)

	var tier := get_survivor_basic_attack_tier()
	var should_chain := tier >= 2 or _rng.randf() <= chain_chance
	if not should_chain:
		return
	var candidates: Array[Node2D] = []
	for enemy_node: Node in get_tree().get_nodes_in_group(&"enemies"):
		if not enemy_node is Node2D or enemy_node == target:
			continue
		var enemy := enemy_node as Node2D
		var chain_radius := [265.0, 285.0, 320.0, 365.0, 430.0][tier - 1] as float
		if target.global_position.distance_to(enemy.global_position) <= chain_radius and _target_is_alive(enemy):
			candidates.append(enemy)
	candidates.sort_custom(func(left: Node2D, right: Node2D) -> bool:
		return target.global_position.distance_squared_to(left.global_position) < target.global_position.distance_squared_to(right.global_position)
	)
	var chain_limit := [1, 1, 2, 3, 5][tier - 1] as int
	if tier <= 2 and blessing_snapshot >= 7:
		chain_limit += 1
	var previous := target
	for chain_index: int in mini(chain_limit, candidates.size()):
		var chained_target := candidates[chain_index]
		var chain_direction := (chained_target.global_position - previous.global_position).normalized()
		var chain_packet := DamagePacket.sniff_dart(self, blessing_snapshot, chain_index + 1)
		var chain_dealt := DamageResolver.apply_with_result(chained_target, chain_packet, chain_direction)
		if chain_dealt > 0.0:
			lightning_arc_requested.emit(previous.global_position, chained_target.global_position, 0.72 - float(chain_index) * 0.12)
			combat_impact.emit(chained_target.global_position, chain_direction, chain_packet, 0.28)
			if tier >= 5:
				thunder_burst_requested.emit(chained_target.global_position, 82.0, 0.42, false)
		previous = chained_target
	audio_requested.emit(&"sniff_chain", clampf(float(candidates.size()) / 2.0, 0.35, 1.0))


func _begin_wayward_bolt() -> void:
	if not has_ability_charge(&"signature") or not _spend_mana(WAYWARD_BOLT_MANA_COST):
		return
	_consume_ability_charge(&"signature")
	var tier := get_survivor_ability_tier(&"signature")
	var segment_counts := [4, 5, 6, 8, 10]
	var segment_durations := [0.095, 0.090, 0.085, 0.080, 0.075]
	var dash_speeds := [1120.0, 1200.0, 1300.0, 1420.0, 1560.0]
	_wayward_segments_remaining = segment_counts[tier - 1] as int
	_wayward_segment_duration = segment_durations[tier - 1] as float
	_wayward_segment_time = _wayward_segment_duration
	_dash_speed = dash_speeds[tier - 1] as float
	_spell_load_snapshot = blessing
	_wayward_hit_count = 0
	_wayward_direction_changes = 0
	_wayward_path = PackedVector2Array([global_position])
	_hit_target_ids.clear()
	_set_attack_radius(52.0 + float(tier) * 3.0)
	_attack_area.monitoring = true
	_set_enemy_phasing(true)
	_invulnerable_time = maxf(_invulnerable_time, float(_wayward_segments_remaining) * _wayward_segment_duration + 0.08)
	_dash_direction = aim_direction.rotated(_rng.randf_range(-0.42, 0.42)).normalized()
	_emit_wayward_segment()
	audio_requested.emit(&"sniff_dash_charge", 0.86)
	announcement_requested.emit("WAYWARD BOLT")
	_set_state(State.WAYWARD_DASH)
	stats_changed.emit()


func _tick_wayward_bolt(delta: float) -> void:
	_wayward_hit_count += _apply_traversal_hits(DamagePacket.sniff_wayward_bolt(self, _spell_load_snapshot))
	_wayward_segment_time -= delta
	if _wayward_segment_time > 0.0:
		return
	_wayward_segments_remaining -= 1
	if _wayward_segments_remaining <= 0:
		_finish_wayward_bolt()
		return
	_choose_next_wayward_direction()
	_wayward_segment_time += _wayward_segment_duration
	_emit_wayward_segment()


func _choose_next_wayward_direction() -> void:
	var turn_magnitude := _rng.randf_range(0.72, 1.95)
	var turn_sign := -1.0 if _rng.randf() < 0.5 else 1.0
	var next_direction := _dash_direction.rotated(turn_magnitude * turn_sign)
	var nearby_targets := _collect_spell_targets(global_position, 620.0)
	if not nearby_targets.is_empty() and _rng.randf() < 0.72:
		var target := nearby_targets[_rng.randi_range(0, nearby_targets.size() - 1)]
		var target_direction := (target.global_position - global_position).normalized()
		next_direction = next_direction.lerp(target_direction, _rng.randf_range(0.18, 0.42)).normalized()
	_dash_direction = next_direction.normalized()
	aim_direction = _dash_direction
	_wayward_direction_changes += 1


func _emit_wayward_segment() -> void:
	_wayward_path.append(global_position)
	var projected_end := global_position + _dash_direction * _dash_speed * _wayward_segment_duration
	lightning_arc_requested.emit(global_position, projected_end, 0.92)
	effect_requested.emit(&"sniff_dash", global_position, _dash_direction, 1.18)
	thunder_burst_requested.emit(global_position, 72.0, 0.42, false)
	audio_requested.emit(&"sniff_step", 0.72)


func _finish_wayward_bolt() -> void:
	_wayward_hit_count += _apply_traversal_hits(DamagePacket.sniff_wayward_bolt(self, _spell_load_snapshot))
	_wayward_path.append(global_position)
	_attack_area.monitoring = false
	_set_enemy_phasing(false)
	velocity = Vector2.ZERO
	_reward_voltaic_load(&"signature", _wayward_hit_count)
	_resolve_spell_backfire(0.11, 14.0, _spell_load_snapshot)
	thunder_burst_requested.emit(global_position, 128.0, 0.78, false)
	audio_requested.emit(&"sniff_dash", 1.0)
	if not is_alive():
		return
	_state_time = 0.24
	_set_state(State.WAYWARD_RECOVERY)


func _begin_tempest_covenant() -> void:
	if not has_ability_charge(&"ability_1") or not _spend_mana(TEMPEST_MANA_COST):
		return
	_consume_ability_charge(&"ability_1")
	var tier := get_survivor_ability_tier(&"ability_1")
	var cast_distances := [300.0, 360.0, 430.0, 500.0, 560.0]
	var radii := [380.0, 450.0, TEMPEST_BASE_RADIUS, 620.0, 760.0]
	_spell_center = global_position + aim_direction * (cast_distances[tier - 1] as float)
	_spell_radius = radii[tier - 1] as float
	_spell_load_snapshot = blessing
	_state_time = [0.62, 0.72, 0.82, 0.90, 1.0][tier - 1] as float
	audio_requested.emit(&"sniff_blessing", 0.92)
	announcement_requested.emit("TEMPEST COVENANT")
	_set_state(State.TEMPEST_STARTUP)
	stats_changed.emit()


func _resolve_tempest_covenant() -> void:
	var tier := get_survivor_ability_tier(&"ability_1")
	var target_limits := [5, 7, 10, 14, 999]
	var targets := _collect_spell_targets(_spell_center, _spell_radius, target_limits[tier - 1] as int)
	var arc_origin := _spell_center + Vector2(0.0, -maxf(520.0, _spell_radius))
	lightning_arc_requested.emit(arc_origin, _spell_center, 0.92)
	thunder_burst_requested.emit(_spell_center, _spell_radius, 0.78, false)
	effect_requested.emit(&"sniff_blessing", _spell_center, aim_direction, 2.4 + 0.18 * float(tier))
	var hit_count := 0
	for chain_index: int in targets.size():
		var target := targets[chain_index]
		var direction := (target.global_position - arc_origin).normalized()
		var packet := DamagePacket.sniff_tempest(self, _spell_load_snapshot, chain_index)
		if DamageResolver.apply_with_result(target, packet, direction) <= 0.0:
			continue
		hit_count += 1
		lightning_arc_requested.emit(arc_origin, target.global_position, maxf(0.62, 1.0 - float(chain_index) * 0.035))
		combat_impact.emit(target.global_position, direction, packet, 0.72)
		if tier >= 4:
			thunder_burst_requested.emit(target.global_position, 92.0 + 14.0 * float(tier), 0.54, false)
		arc_origin = target.global_position
	_reward_voltaic_load(&"ability_1", hit_count)
	_resolve_spell_backfire(0.10, 13.0, _spell_load_snapshot)
	audio_requested.emit(&"sniff_chain", 1.0)
	_state_time = 0.46
	_set_state(State.TEMPEST_RECOVERY)


func _begin_cataclysm_discharge() -> void:
	if blessing <= 0 or not has_ability_charge(&"ability_2") or not _spend_mana(DISCHARGE_MANA_COST):
		return
	_consume_ability_charge(&"ability_2")
	var tier := get_survivor_ability_tier(&"ability_2")
	var base_radii := [300.0, 340.0, DISCHARGE_BASE_RADIUS, 450.0, 520.0]
	var stack_radii := [38.0, 44.0, DISCHARGE_STACK_RADIUS, 60.0, 70.0]
	_spell_center = global_position
	_spell_load_snapshot = blessing
	_spell_radius = (base_radii[tier - 1] as float) + (stack_radii[tier - 1] as float) * float(_spell_load_snapshot)
	spend_blessing(_spell_load_snapshot)
	_state_time = [0.55, 0.68, 0.82, 0.92, 1.0][tier - 1] as float
	audio_requested.emit(&"sniff_surge_charge", float(_spell_load_snapshot) / float(MAX_VOLTAIC_LOAD))
	announcement_requested.emit("CATACLYSM DISCHARGE")
	_set_state(State.DISCHARGE_STARTUP)
	stats_changed.emit()


func _resolve_cataclysm_discharge() -> void:
	var targets := _collect_spell_targets(global_position, _spell_radius)
	var arc_origin := global_position
	var hit_count := 0
	for target: Node2D in targets:
		var direction := (target.global_position - global_position).normalized()
		var packet := DamagePacket.sniff_discharge(self, _spell_load_snapshot)
		if DamageResolver.apply_with_result(target, packet, direction) <= 0.0:
			continue
		hit_count += 1
		lightning_arc_requested.emit(arc_origin, target.global_position, 1.0)
		combat_impact.emit(target.global_position, direction, packet, 1.0)
		arc_origin = target.global_position
	thunder_burst_requested.emit(global_position, _spell_radius, clampf(0.35 + float(_spell_load_snapshot) * 0.065, 0.0, 1.0), true)
	_reward_voltaic_load(&"ability_2", hit_count)
	_resolve_spell_backfire(0.06 + float(_spell_load_snapshot) * 0.012, 7.0 + float(_spell_load_snapshot) * 2.4, _spell_load_snapshot)
	audio_requested.emit(&"sniff_surge", clampf(float(_spell_load_snapshot) / float(MAX_VOLTAIC_LOAD), 0.35, 1.0))
	_state_time = 0.58
	_set_state(State.DISCHARGE_RECOVERY)
	stats_changed.emit()


func _collect_spell_targets(center: Vector2, radius: float, limit := 999) -> Array[Node2D]:
	var targets: Array[Node2D] = []
	for enemy_node: Node in get_tree().get_nodes_in_group(&"enemies"):
		if not enemy_node is Node2D:
			continue
		var target := enemy_node as Node2D
		if _target_is_alive(target) and center.distance_to(target.global_position) <= radius:
			targets.append(target)
	targets.sort_custom(func(left: Node2D, right: Node2D) -> bool:
		return center.distance_squared_to(left.global_position) < center.distance_squared_to(right.global_position)
	)
	if targets.size() > limit:
		targets.resize(limit)
	return targets


func _resolve_spell_backfire(base_chance: float, base_damage: float, load_snapshot: int) -> bool:
	var forced_result := _backfire_override
	_backfire_override = -1
	var backfire_chance := clampf(base_chance + float(load_snapshot) * 0.025, 0.0, 0.58)
	_last_spell_backfired = forced_result > 0 or (forced_result < 0 and _rng.randf() < backfire_chance)
	if _last_spell_backfired:
		_apply_storm_feedback(base_damage * (1.0 + float(load_snapshot) * 0.08), true)
	return _last_spell_backfired


func _begin_flashstep() -> void:
	if not has_ability_charge(&"evade") or not _spend_mana(FLASHSTEP_MANA_COST):
		return
	_consume_ability_charge(&"evade")
	var tier := get_survivor_ability_tier(&"evade")
	var move_input := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	_dash_direction = move_input.normalized() if not move_input.is_zero_approx() else aim_direction
	var distances := [104.0, 132.0, 158.0, 198.0, 242.0]
	var durations := [0.10, 0.115, 0.13, 0.145, 0.16]
	var distance := distances[tier - 1] as float
	_state_time = durations[tier - 1] as float
	_dash_speed = distance / _state_time
	_hit_target_ids.clear()
	_set_attack_radius(43.0)
	_attack_area.monitoring = tier >= 2
	_set_enemy_phasing(tier >= 2)
	var invulnerability := [0.08, 0.15, 0.23, 0.32, 0.45][tier - 1] as float
	_invulnerable_time = maxf(_invulnerable_time, invulnerability)
	effect_requested.emit(&"sniff_dash", global_position, _dash_direction, 0.94)
	lightning_arc_requested.emit(global_position, global_position + _dash_direction * distance, 0.56)
	audio_requested.emit(&"sniff_step", 0.55)
	_set_state(State.FLASHSTEP)
	stats_changed.emit()


func _apply_flashstep_hits() -> void:
	_apply_traversal_hits(DamagePacket.sniff_flashstep(self, blessing))


func _resolve_flashstep_arrival() -> void:
	var tier := get_survivor_ability_tier(&"evade")
	var radius := 112.0 if tier == 4 else 158.0
	var packet := DamagePacket.sniff_flashstep(self, blessing)
	packet.health_damage *= 0.72 if tier == 4 else 1.18
	packet.resolve_damage *= 0.80 if tier == 4 else 1.32
	for enemy_node: Node in get_tree().get_nodes_in_group(&"enemies"):
		if not enemy_node is Node2D:
			continue
		var target := enemy_node as Node2D
		if not _target_is_alive(target) or global_position.distance_to(target.global_position) > radius:
			continue
		var direction := (target.global_position - global_position).normalized()
		if DamageResolver.apply_with_result(target, packet, direction) > 0.0:
			lightning_arc_requested.emit(global_position, target.global_position, 0.72)
	thunder_burst_requested.emit(global_position, radius, 0.68 if tier == 4 else 1.0, false)


func _apply_traversal_hits(packet: DamagePacket) -> int:
	var hit_count := 0
	for hurtbox: Area2D in _attack_area.get_overlapping_areas():
		var target := hurtbox.get_parent() as Node2D
		if not is_instance_valid(target) or not target.is_in_group(&"enemies"):
			continue
		var target_id := target.get_instance_id()
		if _hit_target_ids.has(target_id):
			continue
		_hit_target_ids[target_id] = true
		var direction := _dash_direction
		var dealt := DamageResolver.apply_with_result(target, packet, direction)
		if dealt <= 0.0:
			continue
		hit_count += 1
		combat_impact.emit(target.global_position, direction, packet, clampf(packet.health_damage / 62.0, 0.24, 0.92))
		lightning_arc_requested.emit(global_position - direction * 36.0, target.global_position, 0.62)
	return hit_count


func _begin_worldstorm() -> void:
	if not has_ability_charge(&"ultimate") or not _spend_mana(WORLDSTORM_MANA_COST):
		return
	_consume_ability_charge(&"ultimate")
	var tier := get_survivor_ability_tier(&"ultimate")
	var radii := [600.0, 800.0, WORLDSTORM_BASE_RADIUS, 1500.0, 2400.0]
	_spell_center = global_position
	_spell_radius = radii[tier - 1] as float
	_spell_load_snapshot = blessing
	_state_time = [0.80, 0.95, 1.10, 1.25, 1.40][tier - 1] as float
	audio_requested.emit(&"sniff_ultimate_charge", 1.0)
	announcement_requested.emit("WORLDSTORM")
	_set_state(State.WORLDSTORM_STARTUP)
	stats_changed.emit()


func _resolve_worldstorm() -> void:
	var tier := get_survivor_ability_tier(&"ultimate")
	var target_limits := [6, 10, 999, 999, 999]
	var targets := _collect_spell_targets(global_position, _spell_radius, target_limits[tier - 1] as int)
	var arc_origin := global_position + Vector2(0.0, -780.0)
	lightning_arc_requested.emit(arc_origin, global_position, 1.0)
	var hit_count := 0
	for target: Node2D in targets:
		var direction := (target.global_position - arc_origin).normalized()
		var packet := DamagePacket.sniff_worldstorm(self, _spell_load_snapshot)
		if DamageResolver.apply_with_result(target, packet, direction) <= 0.0:
			continue
		hit_count += 1
		lightning_arc_requested.emit(arc_origin, target.global_position, 1.0)
		combat_impact.emit(target.global_position, direction, packet, 1.0)
		if tier >= 4:
			var aftershock := DamagePacket.sniff_worldstorm(self, _spell_load_snapshot)
			aftershock.health_damage *= 0.42 if tier == 4 else 0.72
			aftershock.resolve_damage *= 0.56 if tier == 4 else 0.86
			DamageResolver.apply(target, aftershock, direction)
		arc_origin = target.global_position
	thunder_burst_requested.emit(global_position, _spell_radius, 1.0, true)
	_reward_voltaic_load(&"ultimate", hit_count)
	_resolve_spell_backfire(0.14, 18.0, _spell_load_snapshot)
	audio_requested.emit(&"sniff_ultimate", 1.0)
	_state_time = 0.82
	_set_state(State.WORLDSTORM_RECOVERY)
	stats_changed.emit()


func receive_hit(packet: DamagePacket, incoming_direction: Vector2) -> float:
	if _state == State.DEAD:
		return 0.0
	if _invulnerable_time > 0.0:
		lightning_arc_requested.emit(global_position - incoming_direction.normalized() * 48.0, global_position, 0.52)
		audio_requested.emit(&"sniff_phase", 0.45)
		return 0.0
	var before := health
	health = maxf(0.0, health - packet.health_damage)
	resolve = maxf(0.0, resolve - packet.resolve_damage)
	_knockback_velocity += incoming_direction.normalized() * packet.knockback_force
	audio_requested.emit(&"sniff_hurt", clampf(packet.health_damage / 36.0, 0.2, 1.0))
	if resolve <= 0.0 and _state != State.WORLDSTORM_STARTUP:
		resolve = get_max_resolve() * 0.42
		_attack_area.monitoring = false
		_state_time = 0.48
		_set_state(State.STAGGER)
	if health <= 0.0:
		_state = State.DEAD
		velocity = Vector2.ZERO
		defeated.emit()
	stats_changed.emit()
	return before - health


func _apply_self_cost(amount: float) -> float:
	if amount <= 0.0 or _state == State.DEAD:
		return 0.0
	var before := health
	health = maxf(1.0, health - amount)
	stats_changed.emit()
	return before - health


func _apply_storm_feedback(amount: float, backfire: bool) -> float:
	if amount <= 0.0 or _state == State.DEAD:
		return 0.0
	var before := health
	health = maxf(0.0, health - amount)
	lightning_arc_requested.emit(global_position + Vector2(-30.0, -44.0), global_position, 0.78 if backfire else 0.46)
	thunder_burst_requested.emit(global_position, 76.0 if backfire else 48.0, 0.52 if backfire else 0.28, false)
	audio_requested.emit(&"sniff_hurt", clampf(amount / 28.0, 0.22, 0.86))
	if backfire:
		announcement_requested.emit("STORM FEEDBACK")
	if health <= 0.0:
		_state = State.DEAD
		velocity = Vector2.ZERO
		defeated.emit()
	stats_changed.emit()
	return before - health


func heal(amount: float) -> void:
	if amount <= 0.0 or _state == State.DEAD:
		return
	health = minf(get_max_health(), health + amount)
	stats_changed.emit()


func restore_mana(amount: float) -> void:
	if amount <= 0.0 or _state == State.DEAD:
		return
	mana = minf(get_max_mana(), mana + amount)
	stats_changed.emit()


func _spend_mana(cost: float) -> bool:
	if mana + 0.001 < cost:
		return false
	mana = maxf(0.0, mana - cost)
	stats_changed.emit()
	return true


func gain_blessing(amount: int) -> void:
	if amount <= 0 or _state == State.DEAD or not is_voltaic_load_unlocked():
		return
	var before := blessing
	blessing = clampi(blessing + amount, 0, MAX_VOLTAIC_LOAD)
	if blessing == MAX_VOLTAIC_LOAD and before < MAX_VOLTAIC_LOAD:
		audio_requested.emit(&"sniff_crowned", 1.0)
		announcement_requested.emit("STORM CRITICAL")
	stats_changed.emit()


func _reward_voltaic_load(ability_slot: StringName, successful_hits: int) -> bool:
	if successful_hits <= 0 or ability_slot in [&"primary", &"evade"] or not is_voltaic_load_unlocked():
		return false
	var before := blessing
	gain_blessing(1)
	return blessing > before


func spend_blessing(amount: int) -> void:
	blessing = maxi(0, blessing - maxi(0, amount))
	stats_changed.emit()


func has_ability_charge(slot: StringName) -> bool:
	return get_ability_charges(slot) > 0


func get_ability_charges(slot: StringName) -> int:
	match slot:
		&"signature":
			return wayward_charges
		&"ability_1":
			return blessing_charges
		&"ability_2":
			return surge_charges
		&"evade":
			return flashstep_charges
		&"ultimate":
			return ultimate_charges
		_:
			return 0


func get_ability_recharge_remaining(slot: StringName) -> float:
	match slot:
		&"signature":
			return wayward_cooldown
		&"ability_1":
			return blessing_cooldown
		&"ability_2":
			return surge_cooldown
		&"evade":
			return flashstep_cooldown
		&"ultimate":
			return ultimate_cooldown
		_:
			return 0.0


func get_ability_recharge_duration(slot: StringName) -> float:
	match slot:
		&"signature":
			return WAYWARD_BOLT_COOLDOWN
		&"ability_1":
			return TEMPEST_COOLDOWN
		&"ability_2":
			return DISCHARGE_COOLDOWN
		&"evade":
			return FLASHSTEP_COOLDOWN
		&"ultimate":
			return WORLDSTORM_COOLDOWN
		_:
			return 0.0


func _set_ability_charges(slot: StringName, charges: int) -> void:
	var clamped_charges := clampi(charges, 0, MAX_ABILITY_CHARGES)
	match slot:
		&"signature":
			wayward_charges = clamped_charges
		&"ability_1":
			blessing_charges = clamped_charges
		&"ability_2":
			surge_charges = clamped_charges
		&"evade":
			flashstep_charges = clamped_charges
		&"ultimate":
			ultimate_charges = clamped_charges


func _set_ability_recharge_remaining(slot: StringName, remaining: float) -> void:
	var clamped_remaining := maxf(0.0, remaining)
	match slot:
		&"signature":
			wayward_cooldown = clamped_remaining
		&"ability_1":
			blessing_cooldown = clamped_remaining
		&"ability_2":
			surge_cooldown = clamped_remaining
		&"evade":
			flashstep_cooldown = clamped_remaining
		&"ultimate":
			ultimate_cooldown = clamped_remaining


func _consume_ability_charge(slot: StringName) -> bool:
	var charges := get_ability_charges(slot)
	if charges <= 0:
		return false
	_set_ability_charges(slot, charges - 1)
	if get_ability_recharge_remaining(slot) <= 0.0:
		_set_ability_recharge_remaining(slot, get_ability_recharge_duration(slot))
	stats_changed.emit()
	return true


func _tick_ability_recharge(delta: float, slot: StringName) -> void:
	var charges := get_ability_charges(slot)
	if charges >= MAX_ABILITY_CHARGES:
		_set_ability_recharge_remaining(slot, 0.0)
		return
	var remaining := get_ability_recharge_remaining(slot) - _survivor_cooldown_delta(delta, slot)
	if remaining > 0.0:
		_set_ability_recharge_remaining(slot, remaining)
		return
	charges += 1
	_set_ability_charges(slot, charges)
	_set_ability_recharge_remaining(slot, get_ability_recharge_duration(slot) + remaining if charges < MAX_ABILITY_CHARGES else 0.0)
	stats_changed.emit()


func _set_attack_radius(radius: float) -> void:
	var circle := _attack_shape.shape as CircleShape2D
	circle.radius = maxf(1.0, radius)


func _set_enemy_phasing(active: bool) -> void:
	collision_mask = 4 if active else 2 | 4


func _target_is_alive(target: Node2D) -> bool:
	return is_instance_valid(target) and target.has_method(&"is_alive") and bool(target.call(&"is_alive"))


func _set_state(next_state: State) -> void:
	_state = next_state
	state_changed.emit(get_state_label())


func _set_using_gamepad(value: bool) -> void:
	_using_gamepad = value


func _clamp_to_movement_bounds() -> void:
	if not _has_movement_bounds:
		return
	global_position.x = clampf(global_position.x, _movement_bounds.position.x, _movement_bounds.end.x)
	global_position.y = clampf(global_position.y, _movement_bounds.position.y, _movement_bounds.end.y)


func is_using_gamepad() -> bool:
	return _using_gamepad


func is_alive() -> bool:
	return _state != State.DEAD


func is_invulnerable() -> bool:
	return _invulnerable_time > 0.0


func get_blessing_count() -> int:
	return blessing


func get_voltaic_load() -> int:
	return blessing


func get_active_spell_radius() -> float:
	return _spell_radius


func get_wayward_direction_changes() -> int:
	return _wayward_direction_changes


func get_wayward_segments_remaining() -> int:
	return _wayward_segments_remaining


func did_last_spell_backfire() -> bool:
	return _last_spell_backfired


func get_state_label() -> String:
	match _state:
		State.DART_STARTUP, State.DART_RECOVERY:
			return "Dart"
		State.WAYWARD_DASH, State.WAYWARD_RECOVERY:
			return "Wayward"
		State.TEMPEST_STARTUP, State.TEMPEST_RECOVERY:
			return "Covenant"
		State.DISCHARGE_STARTUP, State.DISCHARGE_RECOVERY:
			return "Discharging"
		State.FLASHSTEP:
			return "Flashstep"
		State.WORLDSTORM_STARTUP:
			return "Worldstorm"
		State.WORLDSTORM_RECOVERY:
			return "Stormwake"
		_:
			return State.keys()[_state].capitalize()


func _draw() -> void:
	draw_set_transform(Vector2(0.0, 24.0), 0.0, Vector2(1.42, 0.40))
	draw_circle(Vector2.ZERO, 27.0, Color(0.0, 0.0, 0.0, 0.38))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	var facing := aim_direction
	var right := facing.orthogonal()
	var cloak := PackedVector2Array([
		-facing * 31.0 + right * 22.0,
		-facing * 41.0,
		-facing * 31.0 - right * 22.0,
		facing * 13.0 - right * 25.0,
		facing * 26.0,
		facing * 13.0 + right * 25.0,
	])
	draw_colored_polygon(cloak, Color("12374a"))
	draw_polyline(cloak + PackedVector2Array([cloak[0]]), Color("38c7e8"), 3.0, true)
	draw_circle(Vector2.ZERO, 22.0, Color("101a25"))
	draw_circle(facing * 4.0, 12.0, Color("efce45"))
	draw_circle(facing * 7.0, 5.0, Color("f5fbff"))

	var bolt := PackedVector2Array([
		-facing * 7.0 - right * 24.0,
		facing * 14.0 - right * 31.0,
		facing * 5.0 - right * 18.0,
		facing * 35.0 - right * 25.0,
	])
	draw_polyline(bolt, Color("f4dd58"), 5.0, true)

	for stack_index: int in blessing:
		var angle := _visual_time * 1.7 + TAU * float(stack_index) / float(MAX_BLESSING)
		var orbit := Vector2.from_angle(angle) * (39.0 + sin(_visual_time * 5.0 + float(stack_index)) * 2.0)
		draw_circle(orbit, 4.0, Color("52dcff"))
		draw_circle(orbit, 1.8, Color("fff29a"))

	if _state == State.TEMPEST_STARTUP:
		var local_center := _spell_center - global_position
		draw_circle(local_center, _spell_radius, Color(0.10, 0.72, 0.96, 0.055))
		draw_arc(local_center, _spell_radius, _visual_time * 0.8, _visual_time * 0.8 + PI * 1.72, 96, Color(0.94, 0.86, 0.25, 0.72), 4.0, true)
		draw_line(local_center + Vector2(0.0, -minf(720.0, _spell_radius * 1.4)), local_center, Color(0.55, 0.90, 1.0, 0.38), 8.0, true)
	if _state == State.WAYWARD_DASH and _wayward_path.size() > 1:
		var local_path := PackedVector2Array()
		for path_point: Vector2 in _wayward_path:
			local_path.append(path_point - global_position)
		local_path.append(Vector2.ZERO)
		draw_polyline(local_path, Color(0.35, 0.88, 1.0, 0.38), 12.0, true)
		draw_polyline(local_path, Color(1.0, 0.91, 0.34, 0.90), 3.0, true)
	if _state == State.DISCHARGE_STARTUP:
		draw_circle(Vector2.ZERO, _spell_radius, Color(0.10, 0.72, 0.96, 0.07))
		draw_arc(Vector2.ZERO, _spell_radius, -_visual_time, TAU - _visual_time, 112, Color(0.94, 0.86, 0.25, 0.82), 5.0, true)
	if _state == State.WORLDSTORM_STARTUP:
		var pulse := 0.72 + sin(_visual_time * 22.0) * 0.18
		draw_circle(Vector2.ZERO, _spell_radius, Color(0.18, 0.75, 1.0, 0.035 * pulse))
		draw_arc(Vector2.ZERO, _spell_radius, 0.0, TAU, 160, Color(0.95, 0.84, 0.22, 0.58 * pulse), 7.0, true)
	if _invulnerable_time > 0.0:
		draw_arc(Vector2.ZERO, 35.0, _visual_time * 5.0, _visual_time * 5.0 + PI * 1.55, 30, Color(0.78, 0.96, 1.0, 0.88), 4.0, true)
	_draw_debug_attack()


func _draw_debug_attack() -> void:
	if not debug_draw_enabled or not _attack_area.monitoring:
		return
	var circle := _attack_shape.shape as CircleShape2D
	draw_circle(Vector2.ZERO, circle.radius, Color(0.12, 0.72, 1.0, 0.09))
	draw_arc(Vector2.ZERO, circle.radius, 0.0, TAU, 72, Color(1.0, 0.86, 0.30, 0.74), 2.0, true)