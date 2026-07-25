class_name NadPlayer
extends CharacterBody2D


const SurvivorAbilityStateScript := preload("res://scripts/survivors/survivor_ability_state.gd")
const SurvivorStatStateScript := preload("res://scripts/survivors/survivor_stat_state.gd")

signal combat_impact(at: Vector2, direction: Vector2, packet: DamagePacket, intensity: float)
signal effect_requested(effect_id: StringName, at: Vector2, direction: Vector2, size_scale: float)
signal audio_requested(cue: StringName, power: float)
signal mind_link_requested(from: Vector2, to: Vector2, power: float)
signal distortion_requested(at: Vector2, radius: float, power: float, kind: StringName)
signal stats_changed
signal state_changed(label: String)
signal announcement_requested(text: String)
signal defeated

enum State {
	FREE,
	FORESEE_STARTUP,
	FORESEE_ACTIVE,
	FORESEE_RECOVERY,
	MANTLE_CHARGE,
	MANTLE_ACTIVE,
	MANTLE_RECOVERY,
	ANCHOR_RECOVERY,
	CASCADE_STARTUP,
	CASCADE_ACTIVE,
	CASCADE_RECOVERY,
	FOLD_SPACE,
	ULTIMATE_STARTUP,
	ULTIMATE_RECOVERY,
	STAGGER,
	DEAD,
}

const MAX_HEALTH := 220.0
const MAX_RESOLVE := 160.0
const MAX_MANA := 100.0
const MOVE_SPEED := 296.0
const INPUT_BUFFER_DURATION := 0.12
const FORESEE_COST := 7.0
const MANTLE_COST := 32.0
const ANCHOR_COST := 18.0
const CASCADE_COST := 24.0
const FOLD_COST := 14.0
const CONDUIT_COST := 50.0
const FORESEE_REACH := 242.0
const MANTLE_MIN_RADIUS := 135.0
const MANTLE_MAX_RADIUS := 230.0
const CASCADE_REACH := 324.0
const CASCADE_HALF_WIDTH := 154.0
const CONDUIT_RADIUS := 600.0

var health := MAX_HEALTH
var resolve := MAX_RESOLVE
var mana := MAX_MANA
var aim_direction := Vector2.RIGHT
var debug_draw_enabled := false

var anchor_cooldown := 0.0
var cascade_cooldown := 0.0
var fold_cooldown := 0.0
var ultimate_cooldown := 0.0

var _state := State.FREE
var _state_time := 0.0
var _using_gamepad := false
var _primary_buffer := 0.0
var _mantle_charge := 0.0
var _mantle_radius := MANTLE_MIN_RADIUS
var _mantle_center_local := Vector2.RIGHT * 190.0
var _fold_direction := Vector2.RIGHT
var _fold_speed := 0.0
var _conduit_radius := CONDUIT_RADIUS
var _invulnerable_time := 0.0
var _knockback_velocity := Vector2.ZERO
var _attack_area: Area2D
var _attack_shape: CollisionShape2D
var _attack_resolved := false
var _anchors: Array[TerrainAnchor] = []
var _visual_time := 0.0
var _survivor_mode := false
var _survivor_target: Node2D
var _survivor_power_multiplier := 1.0
var _survivor_abilities = SurvivorAbilityStateScript.new()
var _survivor_stats = SurvivorStatStateScript.new()
var _fold_reset_defeats: Dictionary = {}


func _ready() -> void:
	InputProfile.ensure_default_bindings()
	add_to_group(&"player")
	collision_layer = 1
	collision_mask = 2 | 4
	z_index = 12

	var body_shape := CollisionShape2D.new()
	var body_circle := CircleShape2D.new()
	body_circle.radius = 28.0
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
	hurt_circle.radius = 33.0
	hurt_shape.shape = hurt_circle
	hurt_shape.position = Vector2(0.0, 4.0)
	hurtbox.add_child(hurt_shape)

	_attack_area = Area2D.new()
	_attack_area.name = "NadAttackArea"
	_attack_area.collision_layer = 8
	_attack_area.collision_mask = 16
	_attack_area.monitoring = false
	_attack_area.monitorable = false
	add_child(_attack_area)
	_attack_shape = CollisionShape2D.new()
	_attack_shape.shape = RectangleShape2D.new()
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
	return _survivor_power_multiplier


func set_survivor_ability_progress(slot: StringName, rank: int, tier: int, power: float, cooldown: float) -> void:
	_survivor_abilities.set_progress(slot, rank, tier, power, cooldown)


func is_survivor_ability_unlocked(slot: StringName) -> bool:
	return not _survivor_mode or _survivor_abilities.is_unlocked(slot)


func get_survivor_ability_rank(slot: StringName) -> int:
	return _survivor_abilities.get_rank(slot)


func get_survivor_ability_tier(slot: StringName) -> int:
	return _survivor_abilities.get_tier(slot) if _survivor_mode else 3


func get_survivor_ability_power_multiplier(slot: StringName) -> float:
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
	return randf() < get_survivor_critical_chance()


func get_max_health() -> float:
	return MAX_HEALTH * _survivor_stats.get_health_multiplier()


func get_max_resolve() -> float:
	return MAX_RESOLVE * _survivor_stats.get_resolve_multiplier()


func get_max_mana() -> float:
	return MAX_MANA * _survivor_stats.get_mana_multiplier()


func get_mana_regen_per_second() -> float:
	return 13.0 * _survivor_stats.get_mana_regen_multiplier()


func get_move_speed() -> float:
	return MOVE_SPEED * _survivor_stats.get_move_speed_multiplier()


func get_survivor_health_regen() -> float:
	return _survivor_stats.get_health_regen()


func _survivor_cooldown_delta(delta: float, slot: StringName) -> float:
	if not _survivor_mode:
		return delta
	if not _survivor_abilities.is_unlocked(slot):
		return 0.0
	return delta / _survivor_abilities.get_cooldown(slot)


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
	_clamp_to_arena()
	_visual_time += delta
	queue_redraw()


func _tick_timers(delta: float) -> void:
	anchor_cooldown = maxf(0.0, anchor_cooldown - _survivor_cooldown_delta(delta, &"ability_1"))
	cascade_cooldown = maxf(0.0, cascade_cooldown - _survivor_cooldown_delta(delta, &"ability_2"))
	fold_cooldown = maxf(0.0, fold_cooldown - _survivor_cooldown_delta(delta, &"evade"))
	ultimate_cooldown = maxf(0.0, ultimate_cooldown - _survivor_cooldown_delta(delta, &"ultimate"))
	_invulnerable_time = maxf(0.0, _invulnerable_time - delta)
	resolve = minf(get_max_resolve(), resolve + delta * 5.8)
	mana = minf(get_max_mana(), mana + delta * get_mana_regen_per_second())
	_anchors = _anchors.filter(func(anchor: TerrainAnchor) -> bool: return is_instance_valid(anchor))
	_check_fold_reset()


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
		State.FORESEE_STARTUP:
			_state_time -= delta
			if _state_time <= 0.0:
				_begin_foresee_active()
		State.FORESEE_ACTIVE:
			if not _attack_resolved:
				_apply_foresee()
			_state_time -= delta
			if _state_time <= 0.0:
				_attack_area.monitoring = false
				_state_time = 0.105
				_set_state(State.FORESEE_RECOVERY)
		State.FORESEE_RECOVERY, State.MANTLE_RECOVERY, State.ANCHOR_RECOVERY, State.CASCADE_RECOVERY, State.ULTIMATE_RECOVERY, State.STAGGER:
			_state_time -= delta
			if _state_time <= 0.0:
				if _primary_buffer > 0.0 and _state != State.STAGGER:
					_primary_buffer = 0.0
					_begin_foresee()
				else:
					_set_state(State.FREE)
		State.MANTLE_CHARGE:
			var tier := get_survivor_ability_tier(&"signature")
			var charge_duration := [0.0, 0.62, 1.05, 1.18, 1.30][tier - 1] as float
			_mantle_charge = 1.0 if charge_duration <= 0.0 else minf(1.0, _mantle_charge + delta / charge_duration)
			var minimum_radius := [104.0, 120.0, MANTLE_MIN_RADIUS, 154.0, 178.0][tier - 1] as float
			var maximum_radius := [104.0, 185.0, MANTLE_MAX_RADIUS, 286.0, 348.0][tier - 1] as float
			_mantle_radius = lerpf(minimum_radius, maximum_radius, CombatMath.shaped_charge(_mantle_charge))
			_mantle_center_local = aim_direction * lerpf(185.0, 265.0, _mantle_charge)
			if not Input.is_action_pressed(&"signature") or _mantle_charge >= 1.0:
				_release_mantle()
		State.MANTLE_ACTIVE:
			if not _attack_resolved:
				_apply_mantle()
			_state_time -= delta
			if _state_time <= 0.0:
				_attack_area.monitoring = false
				_state_time = 0.36
				_set_state(State.MANTLE_RECOVERY)
		State.CASCADE_STARTUP:
			_state_time -= delta
			if _state_time <= 0.0:
				_begin_cascade_active()
		State.CASCADE_ACTIVE:
			if not _attack_resolved:
				_apply_cascade()
			_state_time -= delta
			if _state_time <= 0.0:
				_attack_area.monitoring = false
				_state_time = 0.34
				_set_state(State.CASCADE_RECOVERY)
		State.FOLD_SPACE:
			_state_time -= delta
			if _state_time <= 0.0:
				collision_mask = 2 | 4
				if get_survivor_ability_tier(&"evade") >= 5:
					_freeze_fold_zone(global_position)
				var fold_tier := get_survivor_ability_tier(&"evade")
				var fold_kind := &"tentacle_breach" if fold_tier >= 5 else (&"rift" if fold_tier >= 3 else &"fold")
				distortion_requested.emit(global_position, 62.0 + 14.0 * float(fold_tier - 1), 0.48, fold_kind)
				_state_time = 0.08
				_set_state(State.MANTLE_RECOVERY)
		State.ULTIMATE_STARTUP:
			_state_time -= delta
			if _state_time <= 0.0:
				_resolve_arcane_conduit()
		State.DEAD:
			pass


func _handle_free_inputs() -> void:
	if Input.is_action_just_pressed(&"ultimate") and is_survivor_ability_unlocked(&"ultimate") and ultimate_cooldown <= 0.0 and mana >= CONDUIT_COST:
		_begin_arcane_conduit()
	elif Input.is_action_just_pressed(&"ability_1") and is_survivor_ability_unlocked(&"ability_1") and anchor_cooldown <= 0.0:
		_cast_terrain_anchor()
	elif Input.is_action_just_pressed(&"ability_2") and is_survivor_ability_unlocked(&"ability_2") and cascade_cooldown <= 0.0 and mana >= CASCADE_COST:
		_begin_mental_cascade()
	elif Input.is_action_just_pressed(&"evade") and is_survivor_ability_unlocked(&"evade") and fold_cooldown <= 0.0:
		_begin_fold_space()
	elif Input.is_action_just_pressed(&"signature") and is_survivor_ability_unlocked(&"signature") and mana >= MANTLE_COST:
		_begin_eldritch_mantle()
	elif (Input.is_action_just_pressed(&"primary") or _primary_buffer > 0.0) and mana >= FORESEE_COST:
		_primary_buffer = 0.0
		_begin_foresee()


func try_survivor_primary(target: Node2D) -> bool:
	if not is_instance_valid(target):
		return false
	_survivor_target = target
	if _state != State.FREE or mana < FORESEE_COST:
		return false
	var target_direction := target.global_position - global_position
	if target_direction.is_zero_approx():
		return false
	aim_direction = target_direction.normalized()
	_primary_buffer = 0.0
	_begin_foresee()
	return true


func _update_movement() -> void:
	var move_input := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	var speed_scale := 1.0
	match _state:
		State.FORESEE_STARTUP:
			speed_scale = 0.70
		State.FORESEE_ACTIVE:
			speed_scale = 0.34
		State.FORESEE_RECOVERY:
			speed_scale = 0.86
		State.MANTLE_CHARGE:
			speed_scale = 0.38
		State.MANTLE_ACTIVE, State.ULTIMATE_STARTUP:
			speed_scale = 0.08
		State.MANTLE_RECOVERY, State.ANCHOR_RECOVERY, State.CASCADE_RECOVERY, State.ULTIMATE_RECOVERY:
			speed_scale = 0.62
		State.CASCADE_STARTUP:
			speed_scale = 0.44
		State.CASCADE_ACTIVE:
			speed_scale = 0.18
		State.FOLD_SPACE:
			velocity = _fold_direction * _fold_speed
			return
		State.STAGGER, State.DEAD:
			speed_scale = 0.0
	velocity = move_input * get_move_speed() * speed_scale + _knockback_velocity
	_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, 40.0)


func _begin_foresee() -> void:
	if not _spend_mana(FORESEE_COST):
		return
	_state_time = 0.055
	audio_requested.emit(&"nad_probe_charge", 0.25)
	_set_state(State.FORESEE_STARTUP)


func _begin_foresee_active() -> void:
	_set_attack_rectangle(FORESEE_REACH, 30.0, aim_direction)
	_attack_resolved = false
	_attack_area.monitoring = true
	_state_time = 0.07
	_set_state(State.FORESEE_ACTIVE)


func _apply_foresee() -> void:
	var nearest: Node2D
	var nearest_distance := INF
	for hurtbox: Area2D in _attack_area.get_overlapping_areas():
		var target := hurtbox.get_parent() as Node2D
		if not is_instance_valid(target) or not target.is_in_group(&"enemies"):
			continue
		var distance := global_position.distance_squared_to(target.global_position)
		if distance < nearest_distance:
			nearest = target
			nearest_distance = distance
	if not is_instance_valid(nearest):
		return
	_attack_resolved = true
	var focus_before := _get_target_focus(nearest)
	var was_locked := bool(nearest.call(&"is_control_locked"))
	nearest.call(&"apply_mental_focus", 1, 7.0)
	nearest.call(&"apply_control_lock", 0.24 + 0.05 * float(focus_before))
	restore_mana(1.0 if was_locked else 5.0)
	var direction := (nearest.global_position - global_position).normalized()
	var packet := DamagePacket.nad_foresee(self, focus_before + 1)
	var dealt := DamageResolver.apply_with_result(nearest, packet, direction)
	if dealt > 0.0:
		combat_impact.emit(nearest.global_position, direction, packet, 0.28 + 0.05 * float(focus_before))
		mind_link_requested.emit(global_position, nearest.global_position, 0.44)
		effect_requested.emit(&"nad_probe", nearest.global_position, direction, 0.78)
	audio_requested.emit(&"nad_probe", 0.35 + 0.08 * float(focus_before))


func _begin_eldritch_mantle() -> void:
	if not _spend_mana(MANTLE_COST):
		return
	_mantle_charge = 0.0
	_mantle_radius = MANTLE_MIN_RADIUS
	_mantle_center_local = aim_direction * 185.0
	audio_requested.emit(&"nad_mantle_charge", 0.32)
	_set_state(State.MANTLE_CHARGE)
	if get_survivor_ability_tier(&"signature") == 1:
		_release_mantle()


func _release_mantle() -> void:
	var tier := get_survivor_ability_tier(&"signature")
	_set_attack_circle(_mantle_radius, _mantle_center_local)
	_attack_resolved = false
	_attack_area.monitoring = true
	_state_time = 0.09
	var distortion_kind := &"abyssal_eye" if tier >= 5 else (&"void_prison" if tier >= 4 else (&"rift" if tier >= 3 else &"mantle"))
	distortion_requested.emit(global_position + _mantle_center_local, _mantle_radius, _mantle_charge, distortion_kind)
	audio_requested.emit(&"nad_mantle", _mantle_charge)
	_set_state(State.MANTLE_ACTIVE)


func _apply_mantle() -> void:
	_attack_resolved = true
	var tier := get_survivor_ability_tier(&"signature")
	var minimum_locks := [0.62, 1.05, 1.60, 2.35, 3.20]
	var maximum_locks := [0.62, 2.35, 3.80, 4.80, 6.0]
	var lock_duration := lerpf(minimum_locks[tier - 1] as float, maximum_locks[tier - 1] as float, CombatMath.shaped_charge(_mantle_charge))
	var packet := DamagePacket.nad_mantle(self, _mantle_charge)
	var mantle_center := global_position + _mantle_center_local
	for hurtbox: Area2D in _attack_area.get_overlapping_areas():
		var target := hurtbox.get_parent() as Node2D
		if not is_instance_valid(target) or not target.is_in_group(&"enemies"):
			continue
		var was_locked := bool(target.call(&"is_control_locked"))
		target.call(&"apply_mental_focus", [1, 1, 2, 3, 5][tier - 1] as int, 8.0)
		target.call(&"apply_control_lock", lock_duration)
		restore_mana(1.5 if was_locked else 4.5)
		if tier >= 5 and target.has_method(&"pull_toward"):
			target.call(&"pull_toward", mantle_center, 520.0)
		var direction := (target.global_position - mantle_center).normalized()
		var dealt := DamageResolver.apply_with_result(target, packet, direction)
		if dealt > 0.0:
			combat_impact.emit(target.global_position, direction, packet, 0.48 + _mantle_charge * 0.42)
			mind_link_requested.emit(mantle_center, target.global_position, 0.62)
		if tier >= 4:
			_tether_mantle_neighbors(target, mantle_center, lock_duration, tier)


func _tether_mantle_neighbors(origin: Node2D, mantle_center: Vector2, lock_duration: float, tier: int) -> void:
	for enemy_node: Node in get_tree().get_nodes_in_group(&"enemies"):
		if not enemy_node is Node2D or enemy_node == origin:
			continue
		var neighbor := enemy_node as Node2D
		if not neighbor.has_method(&"is_alive") or not bool(neighbor.call(&"is_alive")) or origin.global_position.distance_to(neighbor.global_position) > (150.0 if tier == 4 else 220.0):
			continue
		neighbor.call(&"apply_mental_focus", 1 if tier == 4 else 2, 8.0)
		var was_locked := bool(neighbor.call(&"is_control_locked"))
		neighbor.call(&"apply_control_lock", lock_duration * (0.42 if tier == 4 else 0.72))
		restore_mana(0.5 if was_locked else 1.5)
		if tier >= 5 and neighbor.has_method(&"pull_toward"):
			neighbor.call(&"pull_toward", mantle_center, 380.0)
		mind_link_requested.emit(origin.global_position, neighbor.global_position, 0.58 if tier == 4 else 0.86)


func _cast_terrain_anchor() -> void:
	_anchors = _anchors.filter(func(anchor: TerrainAnchor) -> bool: return is_instance_valid(anchor))
	var tier := get_survivor_ability_tier(&"ability_1")
	var maximum_anchors := [1, 2, 3, 4, 5][tier - 1] as int
	if _anchors.size() >= maximum_anchors:
		_detonate_anchors()
		return
	if not _spend_mana(ANCHOR_COST):
		return
	var anchor := TerrainAnchor.new()
	anchor.configure(self, tier)
	get_parent().add_child(anchor)
	anchor.global_position = global_position + aim_direction * 265.0
	_anchors.append(anchor)
	anchor_cooldown = 0.75
	var distortion_kind := &"tentacle_breach" if tier >= 5 else (&"void_anchor" if tier >= 3 else &"anchor_place")
	distortion_requested.emit(anchor.global_position, anchor.get_radius(), 0.35 + 0.10 * float(tier - 1), distortion_kind)
	audio_requested.emit(&"nad_anchor_place", float(_anchors.size()) / float(maximum_anchors))
	_state_time = 0.16
	_set_state(State.ANCHOR_RECOVERY)
	stats_changed.emit()


func _detonate_anchors() -> void:
	var active_anchors: Array[TerrainAnchor] = _anchors.duplicate()
	_anchors.clear()
	for anchor: TerrainAnchor in active_anchors:
		if is_instance_valid(anchor):
			anchor.detonate()
	anchor_cooldown = 8.0
	audio_requested.emit(&"nad_anchor_detonate", 1.0)
	announcement_requested.emit("THOUGHT-LATTICE COLLAPSE")
	_state_time = 0.28
	_set_state(State.ANCHOR_RECOVERY)
	stats_changed.emit()


func on_anchor_hit(target: Node2D, at: Vector2, direction: Vector2, packet: DamagePacket) -> void:
	combat_impact.emit(target.global_position, direction, packet, 0.56)
	mind_link_requested.emit(at, target.global_position, 0.58)
	restore_mana(1.5)


func on_anchor_detonated(at: Vector2, hit_count: int, tier: int) -> void:
	var distortion_kind := &"tentacle_breach" if tier >= 5 else (&"void_anchor" if tier >= 3 else &"anchor_detonate")
	distortion_requested.emit(at, TerrainAnchor.RADIUS, clampf(float(hit_count) / 3.0 + 0.08 * float(tier - 1), 0.38, 1.0), distortion_kind)


func on_anchor_removed(anchor: TerrainAnchor) -> void:
	_anchors.erase(anchor)
	stats_changed.emit()


func _begin_mental_cascade() -> void:
	if not _spend_mana(CASCADE_COST):
		return
	cascade_cooldown = 6.5
	_state_time = 0.17
	audio_requested.emit(&"nad_cascade_charge", 0.62)
	_set_state(State.CASCADE_STARTUP)
	stats_changed.emit()


func _begin_cascade_active() -> void:
	var tier := get_survivor_ability_tier(&"ability_2")
	var reaches := [220.0, 278.0, CASCADE_REACH, 386.0, 468.0]
	var half_widths := [68.0, 108.0, CASCADE_HALF_WIDTH, 196.0, 248.0]
	var cascade_reach := reaches[tier - 1] as float
	_set_attack_cone(cascade_reach, half_widths[tier - 1] as float, aim_direction)
	_attack_resolved = false
	_attack_area.monitoring = true
	_state_time = 0.09
	var distortion_kind := &"eldritch_web" if tier >= 5 else (&"void_web" if tier >= 4 else (&"rift" if tier >= 2 else &"cascade"))
	distortion_requested.emit(global_position + aim_direction * cascade_reach * 0.52, cascade_reach * 0.55, 0.68 + 0.06 * float(tier - 1), distortion_kind)
	audio_requested.emit(&"nad_cascade", 0.72)
	_set_state(State.CASCADE_ACTIVE)


func _apply_cascade() -> void:
	_attack_resolved = true
	var tier := get_survivor_ability_tier(&"ability_2")
	var directly_hit: Array[Node2D] = []
	var direct_ids: Dictionary = {}
	var extensions := 0
	var direct_lock_found := false
	for hurtbox: Area2D in _attack_area.get_overlapping_areas():
		var target := hurtbox.get_parent() as Node2D
		if not is_instance_valid(target) or not target.is_in_group(&"enemies"):
			continue
		var focus_before := _get_target_focus(target)
		var was_locked := bool(target.call(&"is_control_locked"))
		direct_lock_found = direct_lock_found or was_locked
		target.call(&"apply_mental_focus", 1, 8.0)
		if was_locked and tier >= 2 and (tier >= 3 or extensions == 0):
			target.call(&"extend_control_lock", 0.55 + 0.10 * float(focus_before), 6.0)
			extensions += 1
			restore_mana(3.0)
		var direction := (target.global_position - global_position).normalized()
		var packet := DamagePacket.nad_cascade(self, focus_before)
		var dealt := DamageResolver.apply_with_result(target, packet, direction)
		if dealt > 0.0:
			directly_hit.append(target)
			direct_ids[target.get_instance_id()] = true
			combat_impact.emit(target.global_position, direction, packet, 0.48 + 0.06 * float(focus_before))
			mind_link_requested.emit(global_position, target.global_position, 0.68)
	if tier >= 4:
		_apply_cascade_web(directly_hit, direct_ids, direct_lock_found, tier)


func _apply_cascade_web(origins: Array[Node2D], excluded_ids: Dictionary, share_lock: bool, tier: int) -> void:
	for enemy_node: Node in get_tree().get_nodes_in_group(&"enemies"):
		if not enemy_node is Node2D:
			continue
		var target := enemy_node as Node2D
		if excluded_ids.has(target.get_instance_id()) or _get_target_focus(target) <= 0:
			continue
		var linked := tier >= 5
		if not linked:
			for origin: Node2D in origins:
				if origin.global_position.distance_to(target.global_position) <= 230.0:
					linked = true
					break
		if not linked:
			continue
		var direction := (target.global_position - global_position).normalized()
		var packet := DamagePacket.nad_cascade(self, _get_target_focus(target))
		packet.health_damage *= 0.54 if tier == 4 else 0.78
		packet.resolve_damage *= 0.68 if tier == 4 else 0.92
		if share_lock and tier >= 5:
			target.call(&"apply_control_lock", 1.6)
		else:
			target.call(&"apply_mental_focus", 1, 8.0)
		if DamageResolver.apply_with_result(target, packet, direction) > 0.0:
			mind_link_requested.emit(origins[0].global_position if not origins.is_empty() else global_position, target.global_position, 0.76)


func _begin_fold_space() -> void:
	if not _spend_mana(FOLD_COST):
		return
	var tier := get_survivor_ability_tier(&"evade")
	var move_input := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	_fold_direction = move_input.normalized() if not move_input.is_zero_approx() else aim_direction
	var distances := [92.0, 132.0, 168.0, 220.0, 268.0]
	var durations := [0.09, 0.105, 0.12, 0.14, 0.16]
	var distance := distances[tier - 1] as float
	if tier >= 4:
		var aimed_anchor := _find_aimed_anchor()
		if is_instance_valid(aimed_anchor):
			var to_anchor := aimed_anchor.global_position - global_position
			_fold_direction = to_anchor.normalized()
			distance = to_anchor.length()
	_state_time = durations[tier - 1] as float
	_fold_speed = distance / _state_time
	_invulnerable_time = [0.0, 0.08, 0.22, 0.32, 0.44][tier - 1] as float
	fold_cooldown = 2.8
	collision_mask = 4 if tier >= 2 else 2 | 4
	if tier >= 5:
		_freeze_fold_zone(global_position)
	var fold_kind := &"tentacle_breach" if tier >= 5 else (&"rift" if tier >= 3 else &"fold")
	distortion_requested.emit(global_position, 58.0 + 12.0 * float(tier - 1), 0.46, fold_kind)
	audio_requested.emit(&"nad_fold", 0.62)
	_set_state(State.FOLD_SPACE)
	stats_changed.emit()


func _find_aimed_anchor() -> TerrainAnchor:
	var best: TerrainAnchor
	var best_distance := INF
	for anchor: TerrainAnchor in _anchors:
		if not is_instance_valid(anchor):
			continue
		var to_anchor := anchor.global_position - global_position
		if to_anchor.length() > 760.0 or aim_direction.dot(to_anchor.normalized()) < 0.82:
			continue
		if to_anchor.length_squared() < best_distance:
			best = anchor
			best_distance = to_anchor.length_squared()
	return best


func _freeze_fold_zone(at: Vector2) -> void:
	for enemy_node: Node in get_tree().get_nodes_in_group(&"enemies"):
		if enemy_node is Node2D and at.distance_to((enemy_node as Node2D).global_position) <= 126.0 and enemy_node.has_method(&"apply_control_lock"):
			enemy_node.call(&"apply_control_lock", 1.25)
	distortion_requested.emit(at, 126.0, 0.82, &"tentacle_breach")


func _check_fold_reset() -> void:
	if not _survivor_mode or get_survivor_ability_tier(&"evade") < 5 or fold_cooldown <= 0.0:
		return
	for enemy_node: Node in get_tree().get_nodes_in_group(&"enemies"):
		if not enemy_node.has_method(&"is_alive") or bool(enemy_node.call(&"is_alive")) or not enemy_node.has_method(&"is_control_locked") or not bool(enemy_node.call(&"is_control_locked")):
			continue
		var target_id := enemy_node.get_instance_id()
		if _fold_reset_defeats.has(target_id):
			continue
		_fold_reset_defeats[target_id] = true
		fold_cooldown = 0.0
		announcement_requested.emit("SPACE REFOLDED")
		break


func _begin_arcane_conduit() -> void:
	if not _spend_mana(CONDUIT_COST):
		return
	ultimate_cooldown = 22.0
	var tier := get_survivor_ability_tier(&"ultimate")
	var radii := [250.0, 420.0, CONDUIT_RADIUS, 780.0, 2200.0]
	_conduit_radius = radii[tier - 1] as float
	_state_time = [0.40, 0.52, 0.64, 0.72, 0.80][tier - 1] as float
	_invulnerable_time = [0.25, 0.85, 1.80, 2.05, 2.40][tier - 1] as float
	_set_attack_circle(_conduit_radius, Vector2.ZERO)
	_attack_area.monitoring = true
	audio_requested.emit(&"nad_ultimate_charge", 1.0)
	announcement_requested.emit("ARCANE CONDUIT")
	_set_state(State.ULTIMATE_STARTUP)
	stats_changed.emit()


func _resolve_arcane_conduit() -> void:
	var tier := get_survivor_ability_tier(&"ultimate")
	var hit_targets: Dictionary = {}
	for hurtbox: Area2D in _attack_area.get_overlapping_areas():
		var target := hurtbox.get_parent() as Node2D
		if not is_instance_valid(target) or not target.is_in_group(&"enemies"):
			continue
		var target_id := target.get_instance_id()
		if hit_targets.has(target_id):
			continue
		hit_targets[target_id] = true
		var focus_before := _get_target_focus(target)
		var was_locked := bool(target.call(&"is_control_locked"))
		target.call(&"apply_mental_focus", [1, 2, 1, 2, 5][tier - 1] as int, 9.0)
		var lock_duration := 0.42 if tier == 1 else (1.25 if tier == 2 else (2.80 + 0.16 * float(focus_before) if was_locked else 0.75))
		if tier == 4 and was_locked:
			lock_duration = 4.5
		elif tier >= 5:
			lock_duration = 6.0
		target.call(&"apply_control_lock", lock_duration)
		restore_mana(2.0 if was_locked else 5.0)
		var direction := (target.global_position - global_position).normalized()
		var packet := DamagePacket.nad_conduit(self, focus_before, was_locked)
		if tier >= 5:
			packet.health_damage *= 1.0 + 0.08 * float(focus_before)
			packet.resolve_damage *= 1.0 + 0.12 * float(focus_before)
		var dealt := DamageResolver.apply_with_result(target, packet, direction)
		if dealt > 0.0:
			combat_impact.emit(target.global_position, direction, packet, 1.0 if was_locked else 0.62)
			mind_link_requested.emit(global_position, target.global_position, 1.0 if was_locked else 0.66)
	_attack_area.monitoring = false
	var distortion_kind := &"abyssal_eye" if tier >= 5 else (&"cosmic_eye" if tier >= 4 else &"conduit")
	distortion_requested.emit(global_position, _conduit_radius, 1.0, distortion_kind)
	audio_requested.emit(&"nad_ultimate", 1.0)
	_state_time = 0.68
	_set_state(State.ULTIMATE_RECOVERY)
	stats_changed.emit()


func receive_hit(packet: DamagePacket, incoming_direction: Vector2) -> float:
	if _state == State.DEAD:
		return 0.0
	if _invulnerable_time > 0.0:
		distortion_requested.emit(global_position, 48.0, 0.44, &"phase")
		audio_requested.emit(&"nad_phase", 0.42)
		return 0.0
	var before := health
	health = maxf(0.0, health - packet.health_damage)
	resolve = maxf(0.0, resolve - packet.resolve_damage)
	_knockback_velocity += incoming_direction.normalized() * packet.knockback_force
	audio_requested.emit(&"nad_hurt", clampf(packet.health_damage / 36.0, 0.2, 1.0))
	if resolve <= 0.0 and _state != State.ULTIMATE_STARTUP:
		resolve = get_max_resolve() * 0.44
		_attack_area.monitoring = false
		collision_mask = 2 | 4
		_state_time = 0.50
		_set_state(State.STAGGER)
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


func _get_target_focus(target: Node2D) -> int:
	return int(target.call(&"get_mental_focus")) if target.has_method(&"get_mental_focus") else 0


func _set_attack_rectangle(reach: float, half_width: float, direction: Vector2) -> void:
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(reach, half_width * 2.0)
	_attack_shape.shape = rectangle
	_attack_shape.position = Vector2(reach * 0.5, 0.0)
	_attack_area.rotation = direction.angle()


func _set_attack_circle(radius: float, local_center: Vector2) -> void:
	var circle := CircleShape2D.new()
	circle.radius = radius
	_attack_shape.shape = circle
	_attack_shape.position = local_center
	_attack_area.rotation = 0.0


func _set_attack_cone(reach: float, half_width: float, direction: Vector2) -> void:
	var cone := ConvexPolygonShape2D.new()
	cone.points = PackedVector2Array([
		Vector2(0.0, -24.0),
		Vector2(reach, -half_width),
		Vector2(reach, half_width),
		Vector2(0.0, 24.0),
	])
	_attack_shape.shape = cone
	_attack_shape.position = Vector2.ZERO
	_attack_area.rotation = direction.angle()


func _set_state(next_state: State) -> void:
	_state = next_state
	state_changed.emit(get_state_label())


func _set_using_gamepad(value: bool) -> void:
	_using_gamepad = value


func _clamp_to_arena() -> void:
	var bounds := ArenaBackdrop.PLAYABLE_RECT.grow(-36.0)
	global_position.x = clampf(global_position.x, bounds.position.x, bounds.end.x)
	global_position.y = clampf(global_position.y, bounds.position.y, bounds.end.y)


func is_using_gamepad() -> bool:
	return _using_gamepad


func is_alive() -> bool:
	return _state != State.DEAD


func is_invulnerable() -> bool:
	return _invulnerable_time > 0.0


func get_anchor_count() -> int:
	return _anchors.size()


func get_mantle_charge_ratio() -> float:
	return _mantle_charge if _state == State.MANTLE_CHARGE else 0.0


func is_mantle_charging() -> bool:
	return _state == State.MANTLE_CHARGE


func get_state_label() -> String:
	match _state:
		State.FORESEE_STARTUP, State.FORESEE_ACTIVE, State.FORESEE_RECOVERY:
			return "Foresee"
		State.MANTLE_CHARGE:
			return "Distorting"
		State.MANTLE_ACTIVE, State.MANTLE_RECOVERY:
			return "Mantle"
		State.ANCHOR_RECOVERY:
			return "Anchoring"
		State.CASCADE_STARTUP, State.CASCADE_ACTIVE, State.CASCADE_RECOVERY:
			return "Cascade"
		State.FOLD_SPACE:
			return "Fold Space"
		State.ULTIMATE_STARTUP:
			return "Conduit"
		State.ULTIMATE_RECOVERY:
			return "Afterimage"
		_:
			return State.keys()[_state].capitalize()


func _draw() -> void:
	draw_set_transform(Vector2(0.0, 25.0), 0.0, Vector2(1.42, 0.40))
	draw_circle(Vector2.ZERO, 28.0, Color(0.0, 0.0, 0.0, 0.38))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	var facing := aim_direction
	var right := facing.orthogonal()
	var mantle := PackedVector2Array([
		-facing * 31.0 + right * 24.0,
		-facing * 43.0,
		-facing * 31.0 - right * 24.0,
		facing * 12.0 - right * 25.0,
		facing * 25.0,
		facing * 12.0 + right * 25.0,
	])
	draw_colored_polygon(mantle, Color("143947"))
	draw_polyline(mantle + PackedVector2Array([mantle[0]]), Color("71d8df"), 3.0, true)
	draw_circle(Vector2.ZERO, 22.0, Color("17212d"))
	draw_circle(facing * 3.0, 13.0, Color("a9e9df"))
	draw_circle(facing * 8.0, 5.0, Color("e9ffb4"))
	draw_line(-facing * 5.0 - right * 18.0, facing * 57.0 - right * 18.0, Color("c4e7b0"), 4.0, true)
	for rune_index: int in 3:
		var angle := _visual_time * (0.72 + float(rune_index) * 0.13) + TAU * float(rune_index) / 3.0
		var rune := Vector2.from_angle(angle) * (35.0 + float(rune_index) * 4.0)
		draw_circle(rune, 3.5, Color("75ebf4"))

	if _state == State.MANTLE_CHARGE:
		draw_circle(_mantle_center_local, _mantle_radius, Color(0.15, 0.70, 0.76, 0.075))
		draw_arc(_mantle_center_local, _mantle_radius, 0.0, TAU, 80, Color(0.62, 0.93, 0.80, 0.74), 3.0, true)
	if _state == State.CASCADE_STARTUP or _state == State.CASCADE_ACTIVE:
		var corners := PackedVector2Array([
			-facing.orthogonal() * 24.0,
			facing * CASCADE_REACH - facing.orthogonal() * CASCADE_HALF_WIDTH,
			facing * CASCADE_REACH + facing.orthogonal() * CASCADE_HALF_WIDTH,
			facing.orthogonal() * 24.0,
		])
		draw_colored_polygon(corners, Color(0.12, 0.68, 0.77, 0.08))
		draw_polyline(corners + PackedVector2Array([corners[0]]), Color(0.62, 0.94, 0.82, 0.68), 2.0, true)
	if _state == State.ULTIMATE_STARTUP:
		var pulse := 0.78 + sin(_visual_time * 19.0) * 0.12
		draw_circle(Vector2.ZERO, CONDUIT_RADIUS, Color(0.16, 0.72, 0.78, 0.035 * pulse))
		draw_arc(Vector2.ZERO, CONDUIT_RADIUS, 0.0, TAU, 120, Color(0.72, 0.96, 0.76, 0.46 * pulse), 5.0, true)
	if _invulnerable_time > 0.0:
		draw_arc(Vector2.ZERO, 38.0, _visual_time * 3.4, _visual_time * 3.4 + PI * 1.42, 30, Color(0.72, 0.98, 0.95, 0.86), 4.0, true)
	_draw_debug_attack()


func _draw_debug_attack() -> void:
	if not debug_draw_enabled or not _attack_area.monitoring:
		return
	if _attack_shape.shape is CircleShape2D:
		var circle := _attack_shape.shape as CircleShape2D
		draw_circle(_attack_shape.position, circle.radius, Color(0.15, 0.72, 0.78, 0.08))
		draw_arc(_attack_shape.position, circle.radius, 0.0, TAU, 80, Color(0.82, 0.96, 0.54, 0.74), 2.0, true)