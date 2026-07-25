class_name KatPlayer
extends CharacterBody2D


const SurvivorAbilityStateScript := preload("res://scripts/survivors/survivor_ability_state.gd")

signal combat_impact(at: Vector2, direction: Vector2, packet: DamagePacket, intensity: float)
signal effect_requested(effect_id: StringName, at: Vector2, direction: Vector2, size_scale: float)
signal audio_requested(cue: StringName, power: float)
signal shield_visual_changed(active: bool)
signal guard_impact(at: Vector2, direction: Vector2, perfect: bool, power: float)
signal stats_changed
signal state_changed(label: String)
signal announcement_requested(text: String)
signal defeated

enum State {
	FREE,
	PRIMARY_STARTUP,
	PRIMARY_ACTIVE,
	PRIMARY_RECOVERY,
	GUARD,
	SLAM_STARTUP,
	SLAM_ACTIVE,
	SLAM_RECOVERY,
	MARCH,
	ABILITY_RECOVERY,
	ULTIMATE_STARTUP,
	ULTIMATE_RECOVERY,
	STAGGER,
	DEAD,
}

const MAX_HEALTH := 340.0
const MAX_RESOLVE := 210.0
const MAX_VITALITY := 100.0
const MAX_WARD := 95.0
const MOVE_SPEED := 284.0
const INPUT_BUFFER_DURATION := 0.12
const PERFECT_GUARD_WINDOW := 0.19

const PRIMARY_STARTUP := [0.075, 0.095, 0.155]
const PRIMARY_ACTIVE := [0.065, 0.075, 0.105]
const PRIMARY_RECOVERY := [0.19, 0.22, 0.34]
const PRIMARY_REACH := [105.0, 116.0, 168.0]
const PRIMARY_HALF_WIDTH := [42.0, 47.0, 66.0]

var health := MAX_HEALTH
var resolve := MAX_RESOLVE
var vitality := 35.0
var ward := 0.0
var aim_direction := Vector2.RIGHT
var debug_draw_enabled := false

var leech_cooldown := 0.0
var halo_cooldown := 0.0
var march_cooldown := 0.0

var _state := State.FREE
var _state_time := 0.0
var _using_gamepad := false
var _combo_stage := 0
var _primary_buffer := 0.0
var _combo_buffered := false
var _guard_elapsed := 0.0
var _absorbed_force := 0.0
var _slam_power := 0.0
var _march_direction := Vector2.RIGHT
var _march_speed := 650.0
var _knockback_velocity := Vector2.ZERO
var _attack_area: Area2D
var _attack_shape: CollisionShape2D
var _hit_target_ids: Dictionary = {}
var _motes: Array[LeechMote] = []
var _halo: MourningHalo
var _survivor_mode := false
var _survivor_target: Node2D
var _survivor_power_multiplier := 1.0
var _survivor_max_health_multiplier := 1.0
var _survivor_abilities = SurvivorAbilityStateScript.new()
var _communion_regen_time := 0.0
var _last_stand_unlocked := false
var _last_stand_available := false


func _ready() -> void:
	InputProfile.ensure_default_bindings()
	add_to_group(&"player")
	collision_layer = 1
	collision_mask = 2 | 4
	z_index = 12

	var body_shape := CollisionShape2D.new()
	var body_circle := CircleShape2D.new()
	body_circle.radius = 31.0
	body_shape.shape = body_circle
	body_shape.position = Vector2(0.0, 5.0)
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
	hurt_circle.radius = 35.0
	hurt_shape.shape = hurt_circle
	hurt_shape.position = Vector2(0.0, 4.0)
	hurtbox.add_child(hurt_shape)

	_attack_area = Area2D.new()
	_attack_area.name = "KatAttackArea"
	_attack_area.collision_layer = 8
	_attack_area.collision_mask = 16
	_attack_area.monitoring = false
	_attack_area.monitorable = false
	add_child(_attack_area)
	_attack_shape = CollisionShape2D.new()
	_attack_shape.shape = RectangleShape2D.new()
	_attack_area.add_child(_attack_shape)
	_set_attack_box(110.0, 44.0, aim_direction)
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
	if slot == &"ultimate" and rank > 0 and tier >= 5 and not _last_stand_unlocked:
		_last_stand_unlocked = true
		_last_stand_available = true


func is_survivor_ability_unlocked(slot: StringName) -> bool:
	return not _survivor_mode or _survivor_abilities.is_unlocked(slot)


func get_survivor_ability_rank(slot: StringName) -> int:
	return _survivor_abilities.get_rank(slot)


func get_survivor_ability_tier(slot: StringName) -> int:
	return _survivor_abilities.get_tier(slot) if _survivor_mode else 3


func get_survivor_ability_power_multiplier(slot: StringName) -> float:
	return _survivor_abilities.get_power(slot) if _survivor_mode else 1.0


func get_max_health() -> float:
	return MAX_HEALTH * _survivor_max_health_multiplier


func apply_survivor_fortitude(amount: float) -> void:
	var previous_max := get_max_health()
	_survivor_max_health_multiplier += maxf(0.0, amount)
	health += get_max_health() - previous_max
	stats_changed.emit()


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
	_tick_cooldowns(delta)
	_update_aim()
	_update_buffers(delta)
	_update_state(delta)
	_update_movement()
	move_and_slide()
	_clamp_to_arena()
	queue_redraw()


func _tick_cooldowns(delta: float) -> void:
	leech_cooldown = maxf(0.0, leech_cooldown - _survivor_cooldown_delta(delta, &"ability_1"))
	halo_cooldown = maxf(0.0, halo_cooldown - _survivor_cooldown_delta(delta, &"ability_2"))
	march_cooldown = maxf(0.0, march_cooldown - _survivor_cooldown_delta(delta, &"evade"))
	resolve = minf(MAX_RESOLVE, resolve + delta * 5.0)
	if _communion_regen_time > 0.0:
		_communion_regen_time = maxf(0.0, _communion_regen_time - delta)
		heal(delta * 3.2)
	_motes = _motes.filter(func(mote: LeechMote) -> bool: return is_instance_valid(mote))


func _update_buffers(delta: float) -> void:
	_primary_buffer = maxf(0.0, _primary_buffer - delta)
	if _state != State.FREE and Input.is_action_just_pressed(&"primary"):
		_primary_buffer = INPUT_BUFFER_DURATION
		if _state == State.PRIMARY_RECOVERY:
			_combo_buffered = true


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
		State.PRIMARY_STARTUP:
			_state_time -= delta
			if _state_time <= 0.0:
				_begin_primary_active()
		State.PRIMARY_ACTIVE:
			_apply_primary_hits()
			_state_time -= delta
			if _state_time <= 0.0:
				_begin_primary_recovery()
		State.PRIMARY_RECOVERY:
			_state_time -= delta
			if _state_time <= 0.07 and _combo_buffered and _combo_stage < 2:
				_combo_buffered = false
				_begin_primary(_combo_stage + 1)
			elif _state_time <= 0.0:
				_combo_stage = 0
				_combo_buffered = false
				_set_state(State.FREE)
		State.GUARD:
			_guard_elapsed += delta
			var guard_cap := [0.55, 0.88, INF, INF, INF][get_survivor_ability_tier(&"signature") - 1] as float
			if not Input.is_action_pressed(&"signature") or _guard_elapsed >= guard_cap:
				_begin_slam()
		State.SLAM_STARTUP:
			_state_time -= delta
			if _state_time <= 0.0:
				_begin_slam_active()
		State.SLAM_ACTIVE:
			_apply_slam_hits()
			_state_time -= delta
			if _state_time <= 0.0:
				_attack_area.monitoring = false
				_state_time = 0.38
				_set_state(State.SLAM_RECOVERY)
		State.SLAM_RECOVERY, State.ABILITY_RECOVERY, State.ULTIMATE_RECOVERY, State.STAGGER:
			_state_time -= delta
			if _state_time <= 0.0:
				_set_state(State.FREE)
		State.MARCH:
			_apply_march_hits()
			_state_time -= delta
			if _state_time <= 0.0:
				_attack_area.monitoring = false
				shield_visual_changed.emit(false)
				if get_survivor_ability_tier(&"evade") >= 4:
					_resolve_march_arrival()
				_set_state(State.FREE)
		State.ULTIMATE_STARTUP:
			_state_time -= delta
			if _state_time <= 0.0:
				_resolve_black_communion()
		State.DEAD:
			pass


func _handle_free_inputs() -> void:
	if Input.is_action_just_pressed(&"ultimate") and is_survivor_ability_unlocked(&"ultimate") and vitality >= MAX_VITALITY:
		_begin_black_communion()
	elif Input.is_action_just_pressed(&"ability_1") and is_survivor_ability_unlocked(&"ability_1") and leech_cooldown <= 0.0:
		_cast_leech_choir()
	elif Input.is_action_just_pressed(&"ability_2") and is_survivor_ability_unlocked(&"ability_2") and halo_cooldown <= 0.0:
		_cast_mourning_halo()
	elif Input.is_action_just_pressed(&"evade") and is_survivor_ability_unlocked(&"evade") and march_cooldown <= 0.0:
		_begin_bastion_march()
	elif Input.is_action_just_pressed(&"signature") and is_survivor_ability_unlocked(&"signature"):
		_begin_guard()
	elif Input.is_action_just_pressed(&"primary") or _primary_buffer > 0.0:
		_primary_buffer = 0.0
		_begin_primary(0)


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
	_begin_primary(0)
	return true


func _update_movement() -> void:
	var move_input := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	var speed_scale := 1.0
	match _state:
		State.PRIMARY_STARTUP:
			speed_scale = 0.56
		State.PRIMARY_ACTIVE:
			speed_scale = 0.20
		State.PRIMARY_RECOVERY:
			speed_scale = 0.72
		State.GUARD:
			speed_scale = 0.38
		State.SLAM_STARTUP:
			speed_scale = 0.20
		State.SLAM_ACTIVE:
			speed_scale = 0.0
		State.SLAM_RECOVERY, State.ABILITY_RECOVERY, State.ULTIMATE_RECOVERY:
			speed_scale = 0.58
		State.ULTIMATE_STARTUP:
			speed_scale = 0.12
		State.STAGGER, State.DEAD:
			speed_scale = 0.0
		State.MARCH:
			velocity = _march_direction * _march_speed
			return
	velocity = move_input * MOVE_SPEED * speed_scale + _knockback_velocity
	_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, 38.0)


func _begin_primary(stage: int) -> void:
	_combo_stage = clampi(stage, 0, 2)
	_hit_target_ids.clear()
	_state_time = float(PRIMARY_STARTUP[_combo_stage])
	_set_state(State.PRIMARY_STARTUP)
	audio_requested.emit(&"kat_swing", float(_combo_stage) / 2.0)


func _begin_primary_active() -> void:
	_state_time = float(PRIMARY_ACTIVE[_combo_stage])
	_set_attack_box(float(PRIMARY_REACH[_combo_stage]), float(PRIMARY_HALF_WIDTH[_combo_stage]), aim_direction)
	_attack_area.monitoring = true
	_set_state(State.PRIMARY_ACTIVE)


func _apply_primary_hits() -> void:
	var packet := DamagePacket.kat_primary(_combo_stage, self)
	_apply_attack_hits(packet, 1 if _combo_stage == 2 else 0, 0.13)


func _begin_primary_recovery() -> void:
	_attack_area.monitoring = false
	_state_time = float(PRIMARY_RECOVERY[_combo_stage])
	_set_state(State.PRIMARY_RECOVERY)


func _begin_guard() -> void:
	_guard_elapsed = 0.0
	_absorbed_force = 0.0
	shield_visual_changed.emit(true)
	audio_requested.emit(&"kat_guard_raise", 0.4)
	_set_state(State.GUARD)


func _begin_slam() -> void:
	shield_visual_changed.emit(false)
	_slam_power = clampf(_guard_elapsed / 1.15 + _absorbed_force / 95.0, 0.0, 1.0)
	_state_time = lerpf(0.16, 0.24, _slam_power)
	audio_requested.emit(&"kat_slam_charge", _slam_power)
	_set_state(State.SLAM_STARTUP)


func _begin_slam_active() -> void:
	_state_time = 0.12
	_hit_target_ids.clear()
	var tier_scale := [0.68, 0.84, 1.0, 1.22, 1.46][get_survivor_ability_tier(&"signature") - 1] as float
	_set_attack_box(lerpf(165.0, 255.0, _slam_power) * tier_scale, lerpf(72.0, 108.0, _slam_power) * tier_scale, aim_direction)
	_attack_area.monitoring = true
	effect_requested.emit(&"kat_absorb", global_position + aim_direction * 45.0, aim_direction, lerpf(1.0, 1.7, _slam_power))
	_set_state(State.SLAM_ACTIVE)


func _apply_slam_hits() -> void:
	var tier := get_survivor_ability_tier(&"signature")
	_apply_attack_hits(DamagePacket.kat_slam(_slam_power, self), 1 if tier == 1 else (2 if tier < 4 else tier - 1), 0.24)


func _begin_bastion_march() -> void:
	var move_input := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	_march_direction = move_input.normalized() if not move_input.is_zero_approx() else aim_direction
	aim_direction = _march_direction
	var tier := get_survivor_ability_tier(&"evade")
	var durations := [0.14, 0.19, 0.24, 0.30, 0.36]
	var speeds := [520.0, 590.0, 650.0, 720.0, 800.0]
	march_cooldown = 3.6
	_state_time = durations[tier - 1] as float
	_march_speed = speeds[tier - 1] as float
	_hit_target_ids.clear()
	_set_attack_box(112.0 * lerpf(0.72, 1.28, float(tier - 1) / 4.0), 56.0, _march_direction)
	_attack_area.monitoring = tier >= 2
	shield_visual_changed.emit(true)
	audio_requested.emit(&"kat_march", 0.65)
	_set_state(State.MARCH)
	stats_changed.emit()


func _apply_march_hits() -> void:
	_apply_attack_hits(DamagePacket.kat_march(self), 1, 0.10)


func _resolve_march_arrival() -> void:
	var tier := get_survivor_ability_tier(&"evade")
	var radius := 135.0 if tier == 4 else 185.0
	var packet := DamagePacket.kat_march(self)
	packet.health_damage *= 0.65 if tier == 4 else 1.0
	packet.resolve_damage *= 0.82 if tier == 4 else 1.25
	for target_node: Node in get_tree().get_nodes_in_group(&"enemies"):
		if not target_node is Node2D or not target_node.has_method(&"is_alive") or not bool(target_node.call(&"is_alive")):
			continue
		var target := target_node as Node2D
		if global_position.distance_to(target.global_position) > radius:
			continue
		var direction := (target.global_position - global_position).normalized()
		DamageResolver.apply(target, packet, direction)
		if tier >= 5 and target.has_method(&"pull_toward"):
			target.call(&"pull_toward", global_position, 260.0)
	ward = minf(MAX_WARD, ward + (10.0 if tier == 4 else 22.0))
	effect_requested.emit(&"kat_absorb", global_position, _march_direction, 1.35 if tier == 4 else 1.85)


func _cast_leech_choir() -> void:
	_motes = _motes.filter(func(mote: LeechMote) -> bool: return is_instance_valid(mote))
	var tier := get_survivor_ability_tier(&"ability_1")
	var maximum_motes := tier
	var spawn_count := mini(3 if tier >= 5 else 2, maximum_motes - _motes.size())
	for spawn_index: int in spawn_count:
		var mote := LeechMote.new()
		mote.configure(self, _motes.size())
		get_parent().add_child(mote)
		mote.global_position = global_position + Vector2(0.0, -24.0)
		_motes.append(mote)
	leech_cooldown = 9.5 if spawn_count > 0 else 2.0
	effect_requested.emit(&"kat_heal", global_position, aim_direction, 1.12)
	audio_requested.emit(&"kat_summon", 0.7)
	_state_time = 0.24
	_set_state(State.ABILITY_RECOVERY)
	stats_changed.emit()


func _cast_mourning_halo() -> void:
	if is_instance_valid(_halo):
		_halo.queue_free()
	_halo = MourningHalo.new()
	_halo.configure(self, get_survivor_ability_tier(&"ability_2"))
	add_child(_halo)
	halo_cooldown = 11.5
	effect_requested.emit(&"kat_curse", global_position, aim_direction, 2.4)
	audio_requested.emit(&"kat_halo", 0.8)
	_state_time = 0.28
	_set_state(State.ABILITY_RECOVERY)
	stats_changed.emit()


func _begin_black_communion() -> void:
	_state_time = 0.62
	_set_state(State.ULTIMATE_STARTUP)
	effect_requested.emit(&"kat_curse", global_position, aim_direction, 3.3)
	audio_requested.emit(&"kat_ultimate_charge", 1.0)
	announcement_requested.emit("BLACK COMMUNION")


func _resolve_black_communion() -> void:
	var total_damage := 0.0
	var affected := 0
	var tier := get_survivor_ability_tier(&"ultimate")
	var rite_radius := [230.0, 310.0, 390.0, 520.0, 720.0][tier - 1] as float
	for target_node: Node in get_tree().get_nodes_in_group(&"enemies"):
		if not target_node is Node2D or not target_node.has_method(&"is_alive") or not bool(target_node.call(&"is_alive")):
			continue
		var target := target_node as Node2D
		var cursed := target.has_method(&"is_cursed") and bool(target.call(&"is_cursed"))
		if global_position.distance_to(target.global_position) > rite_radius and (tier < 3 or not cursed):
			continue
		var stacks := int(target.call(&"get_curse_stacks")) if target.has_method(&"get_curse_stacks") else 0
		if target.has_method(&"pull_toward"):
			target.call(&"pull_toward", global_position, 250.0)
		var direction := (target.global_position - global_position).normalized()
		var packet := DamagePacket.kat_communion(self, stacks)
		var dealt := DamageResolver.apply_with_result(target, packet, direction)
		if tier >= 5:
			var echo := DamagePacket.kat_communion(self, stacks)
			echo.health_damage *= 0.48
			echo.resolve_damage *= 0.62
			dealt += DamageResolver.apply_with_result(target, echo, direction)
		total_damage += dealt
		affected += 1
		combat_impact.emit(target.global_position, direction, packet, 1.0)
		effect_requested.emit(&"kat_curse", target.global_position, direction, 1.7)
	heal(total_damage * 0.22)
	ward = minf(MAX_WARD, ward + 16.0 * float(affected))
	if tier >= 4:
		_communion_regen_time = 6.0 if tier == 4 else 9.0
	vitality = 0.0
	effect_requested.emit(&"kat_communion", global_position, aim_direction, 2.45)
	audio_requested.emit(&"kat_ultimate", 1.0)
	_state_time = 0.72
	_set_state(State.ULTIMATE_RECOVERY)
	stats_changed.emit()


func _apply_attack_hits(packet: DamagePacket, curse_stacks: int, drain_ratio: float) -> void:
	for hurtbox: Area2D in _attack_area.get_overlapping_areas():
		var target := hurtbox.get_parent() as Node2D
		if not is_instance_valid(target) or not target.is_in_group(&"enemies"):
			continue
		var target_id := target.get_instance_id()
		if _hit_target_ids.has(target_id):
			continue
		_hit_target_ids[target_id] = true
		var direction := (target.global_position - global_position).normalized()
		var dealt := DamageResolver.apply_with_result(target, packet, direction)
		if packet.survivor_ability_slot == &"signature" and get_survivor_ability_tier(&"signature") >= 5:
			var echo := DamagePacket.kat_slam(_slam_power * 0.75, self)
			echo.health_damage *= 0.52
			echo.resolve_damage *= 0.68
			dealt += DamageResolver.apply_with_result(target, echo, direction)
			ward = minf(MAX_WARD, ward + 7.0)
		if curse_stacks > 0 and target.has_method(&"apply_curse"):
			target.call(&"apply_curse", curse_stacks, 6.0)
		if dealt > 0.0:
			heal(dealt * drain_ratio)
			gain_vitality(dealt * 0.16 + float(curse_stacks) * 3.0)
			combat_impact.emit(target.global_position - direction * 24.0, direction, packet, clampf(packet.health_damage / 80.0, 0.2, 1.0))


func receive_hit(packet: DamagePacket, incoming_direction: Vector2) -> float:
	if _state == State.DEAD:
		return 0.0
	var attacker_direction := -incoming_direction.normalized()
	var in_front := aim_direction.dot(attacker_direction) >= cos(deg_to_rad(72.0))
	if (_state == State.GUARD or _state == State.MARCH) and in_front:
		var perfect := _state == State.GUARD and _guard_elapsed <= PERFECT_GUARD_WINDOW
		var taken := 0.0 if perfect else packet.health_damage * 0.12
		_absorbed_force += packet.health_damage
		gain_vitality(packet.health_damage * (0.72 if perfect else 0.36))
		if perfect and is_instance_valid(packet.source) and packet.source.has_method(&"apply_curse"):
			packet.source.call(&"apply_curse", 2, 6.0)
		_apply_health_damage(taken)
		guard_impact.emit(global_position + attacker_direction * 34.0, attacker_direction, perfect, packet.health_damage)
		audio_requested.emit(&"kat_perfect_guard" if perfect else &"kat_guard", clampf(packet.health_damage / 35.0, 0.2, 1.0))
		stats_changed.emit()
		return taken

	var remaining_damage := packet.health_damage
	if ward > 0.0:
		var ward_absorb := minf(ward, remaining_damage)
		ward -= ward_absorb
		remaining_damage -= ward_absorb
	_apply_health_damage(remaining_damage)
	if health <= 0.0 and _last_stand_available:
		_last_stand_available = false
		health = get_max_health() * 0.35
		ward = MAX_WARD
		resolve = MAX_RESOLVE
		vitality = 0.0
		effect_requested.emit(&"kat_communion", global_position, aim_direction, 2.6)
		announcement_requested.emit("EVERLASTING OATH")
	resolve = maxf(0.0, resolve - packet.resolve_damage)
	_knockback_velocity += incoming_direction.normalized() * packet.knockback_force
	audio_requested.emit(&"kat_hurt", clampf(packet.health_damage / 40.0, 0.2, 1.0))
	if resolve <= 0.0 and _state != State.ULTIMATE_STARTUP:
		resolve = MAX_RESOLVE * 0.45
		shield_visual_changed.emit(false)
		_attack_area.monitoring = false
		_state_time = 0.52
		_set_state(State.STAGGER)
	if health <= 0.0:
		_state = State.DEAD
		velocity = Vector2.ZERO
		defeated.emit()
	stats_changed.emit()
	return remaining_damage


func _apply_health_damage(amount: float) -> void:
	health = maxf(0.0, health - maxf(0.0, amount))


func heal(amount: float) -> void:
	if amount <= 0.0 or _state == State.DEAD:
		return
	var missing := get_max_health() - health
	var restored := minf(missing, amount)
	health += restored
	var excess := amount - restored
	if excess > 0.0:
		ward = minf(MAX_WARD, ward + excess)
	stats_changed.emit()


func gain_vitality(amount: float) -> void:
	vitality = clampf(vitality + amount, 0.0, MAX_VITALITY)
	stats_changed.emit()


func on_leech_hit(target: Node2D, dealt: float, direction: Vector2) -> void:
	if dealt <= 0.0:
		return
	heal(dealt * 0.58)
	gain_vitality(6.0)
	if get_survivor_ability_tier(&"ability_1") >= 5:
		ward = minf(MAX_WARD, ward + dealt * 0.34)
	effect_requested.emit(&"kat_heal", global_position, direction, 0.72)
	effect_requested.emit(&"kat_curse", target.global_position, direction, 0.75)
	audio_requested.emit(&"kat_drain", 0.35)


func on_halo_target_hit(target: Node, dealt: float, pulse_index: int) -> void:
	if dealt > 0.0 and pulse_index % 2 == 0:
		effect_requested.emit(&"kat_curse", target.global_position, Vector2.UP, 0.82)


func on_halo_pulse(total_damage: float, hit_count: int) -> void:
	var tier := get_survivor_ability_tier(&"ability_2")
	if tier >= 4 and hit_count > 0:
		ward = minf(MAX_WARD, ward + float(hit_count) * (1.4 if tier == 4 else 2.4))
	if hit_count <= 0:
		return
	heal(total_damage * 0.38)
	gain_vitality(2.4 * float(hit_count))
	effect_requested.emit(&"kat_heal", global_position, Vector2.UP, 0.78)
	audio_requested.emit(&"kat_drain", clampf(float(hit_count) / 4.0, 0.25, 0.8))


func _set_attack_box(reach: float, half_width: float, direction: Vector2) -> void:
	var rectangle := _attack_shape.shape as RectangleShape2D
	rectangle.size = Vector2(reach, half_width * 2.0)
	_attack_shape.position = Vector2(reach * 0.5, 0.0)
	_attack_area.rotation = direction.angle()


func _set_state(next_state: State) -> void:
	_state = next_state
	state_changed.emit(get_state_label())


func _set_using_gamepad(value: bool) -> void:
	_using_gamepad = value


func _clamp_to_arena() -> void:
	var bounds := ArenaBackdrop.PLAYABLE_RECT.grow(-38.0)
	global_position.x = clampf(global_position.x, bounds.position.x, bounds.end.x)
	global_position.y = clampf(global_position.y, bounds.position.y, bounds.end.y)


func is_using_gamepad() -> bool:
	return _using_gamepad


func is_alive() -> bool:
	return _state != State.DEAD


func get_state_label() -> String:
	match _state:
		State.PRIMARY_STARTUP, State.PRIMARY_ACTIVE, State.PRIMARY_RECOVERY:
			return "Combo %d" % (_combo_stage + 1)
		State.SLAM_STARTUP, State.SLAM_ACTIVE, State.SLAM_RECOVERY:
			return "Shield Slam"
		State.ABILITY_RECOVERY:
			return "Invoking"
		State.ULTIMATE_STARTUP:
			return "Communion"
		State.ULTIMATE_RECOVERY:
			return "Aftershock"
		_:
			return State.keys()[_state].capitalize()


func get_mote_count() -> int:
	return _motes.size()


func is_halo_active() -> bool:
	return is_instance_valid(_halo)


func _draw() -> void:
	draw_set_transform(Vector2(0.0, 25.0), 0.0, Vector2(1.5, 0.42))
	draw_circle(Vector2.ZERO, 29.0, Color(0.0, 0.0, 0.0, 0.40))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	var facing := aim_direction
	var right := facing.orthogonal()
	var cape := PackedVector2Array([
		-facing * 31.0 + right * 27.0,
		-facing * 43.0,
		-facing * 31.0 - right * 27.0,
		facing * 9.0 - right * 23.0,
		facing * 18.0,
		facing * 9.0 + right * 23.0,
	])
	draw_colored_polygon(cape, Color("3b0d1c"))
	draw_polyline(cape + PackedVector2Array([cape[0]]), Color("a92f45"), 3.0, true)
	draw_circle(Vector2.ZERO, 25.0, Color("d8c8ae"))
	draw_circle(-facing * 3.0, 17.0, Color("181921"))
	draw_circle(facing * 6.0, 7.0, Color("ef5365"))

	var shield_center := facing * 31.0 + right * 19.0
	var shield_color := Color("f4b15e") if _state == State.GUARD or _state == State.MARCH else Color("b9364d")
	draw_arc(shield_center, 28.0, facing.angle() - 1.15, facing.angle() + 1.15, 28, shield_color, 9.0, true)
	draw_arc(shield_center, 20.0, facing.angle() - 1.05, facing.angle() + 1.05, 24, Color("28111a"), 4.0, true)
	draw_line(facing * 25.0 - right * 18.0, facing * 70.0 - right * 18.0, Color("e5d8ba"), 4.0, true)

	if _state == State.PRIMARY_ACTIVE:
		var arc_radius := float(PRIMARY_REACH[_combo_stage]) * 0.72
		var arc_width := 5.0 + float(_combo_stage) * 3.0
		draw_arc(Vector2.ZERO, arc_radius, facing.angle() - 0.72, facing.angle() + 0.72, 30, Color(1.0, 0.62, 0.27, 0.78), arc_width, true)
	if _state == State.SLAM_STARTUP or _state == State.SLAM_ACTIVE:
		draw_arc(Vector2.ZERO, lerpf(76.0, 116.0, _slam_power), facing.angle() - 0.84, facing.angle() + 0.84, 34, Color(0.95, 0.20, 0.32, 0.72), 8.0, true)
	if ward > 0.0:
		draw_arc(Vector2.ZERO, 40.0, 0.0, TAU * ward / MAX_WARD, 40, Color(0.72, 0.37, 0.92, 0.72), 3.0, true)
	_draw_debug_attack()


func _draw_debug_attack() -> void:
	if not debug_draw_enabled or not _attack_area.monitoring:
		return
	var rectangle := _attack_shape.shape as RectangleShape2D
	var reach := rectangle.size.x
	var half_width := rectangle.size.y * 0.5
	var facing := Vector2.from_angle(_attack_area.rotation)
	var right := facing.orthogonal()
	var corners := PackedVector2Array([
		right * half_width,
		facing * reach + right * half_width,
		facing * reach - right * half_width,
		-right * half_width,
	])
	draw_colored_polygon(corners, Color(0.95, 0.20, 0.22, 0.12))
	draw_polyline(corners + PackedVector2Array([corners[0]]), Color(1.0, 0.74, 0.34, 0.70), 2.0, true)