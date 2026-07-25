class_name SniffPlayer
extends CharacterBody2D


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
	DASH_CHARGE,
	DASH_ACTIVE,
	DASH_RECOVERY,
	BLESSING_RECOVERY,
	SURGE_STARTUP,
	SURGE_RECOVERY,
	FLASHSTEP,
	ULTIMATE_STARTUP,
	ULTIMATE_RECOVERY,
	STAGGER,
	DEAD,
}

const MAX_HEALTH := 245.0
const MAX_RESOLVE := 138.0
const MAX_BLESSING := 10
const MOVE_SPEED := 332.0
const INPUT_BUFFER_DURATION := 0.12
const DASH_MIN_DISTANCE := 185.0
const DASH_MAX_DISTANCE := 445.0
const FLASHSTEP_COOLDOWN := 0.75
const SURGE_BASE_RADIUS := 148.0
const SURGE_STACK_RADIUS := 8.0
const ULTIMATE_RADIUS := 560.0

var health := MAX_HEALTH
var resolve := MAX_RESOLVE
var blessing := 0
var aim_direction := Vector2.RIGHT
var debug_draw_enabled := false
var chain_chance := 0.30

var blessing_cooldown := 0.0
var surge_cooldown := 0.0
var flashstep_cooldown := 0.0
var ultimate_cooldown := 0.0

var _state := State.FREE
var _state_time := 0.0
var _using_gamepad := false
var _primary_buffer := 0.0
var _dash_charge := 0.0
var _dash_direction := Vector2.RIGHT
var _dash_speed := 0.0
var _dash_spent := 0
var _surge_spent := 0
var _surge_radius := SURGE_BASE_RADIUS
var _ultimate_snapshot := 0
var _ultimate_crowned := false
var _invulnerable_time := 0.0
var _overcharge_time := 0.0
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
	return _survivor_power_multiplier


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
	blessing_cooldown = maxf(0.0, blessing_cooldown - delta)
	surge_cooldown = maxf(0.0, surge_cooldown - delta)
	flashstep_cooldown = maxf(0.0, flashstep_cooldown - delta)
	ultimate_cooldown = maxf(0.0, ultimate_cooldown - delta)
	_invulnerable_time = maxf(0.0, _invulnerable_time - delta)
	_overcharge_time = maxf(0.0, _overcharge_time - delta)
	resolve = minf(MAX_RESOLVE, resolve + delta * 6.5)


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
		State.DART_RECOVERY, State.DASH_RECOVERY, State.BLESSING_RECOVERY, State.SURGE_RECOVERY, State.ULTIMATE_RECOVERY, State.STAGGER:
			_state_time -= delta
			if _state_time <= 0.0:
				if _primary_buffer > 0.0 and _state != State.STAGGER:
					_primary_buffer = 0.0
					_begin_dart()
				else:
					_set_state(State.FREE)
		State.DASH_CHARGE:
			_dash_charge = minf(1.0, _dash_charge + delta / 0.82)
			if not Input.is_action_pressed(&"signature") or _dash_charge >= 1.0:
				_release_thunder_dash()
		State.DASH_ACTIVE:
			_apply_dash_hits()
			_state_time -= delta
			if _state_time <= 0.0:
				_attack_area.monitoring = false
				_set_enemy_phasing(false)
				_state_time = 0.19
				_set_state(State.DASH_RECOVERY)
		State.SURGE_STARTUP:
			_state_time -= delta
			if _state_time <= 0.0:
				_resolve_explosive_surge()
		State.FLASHSTEP:
			_apply_flashstep_hits()
			_state_time -= delta
			if _state_time <= 0.0:
				_attack_area.monitoring = false
				_set_enemy_phasing(false)
				_state_time = 0.09
				_set_state(State.DASH_RECOVERY)
		State.ULTIMATE_STARTUP:
			_state_time -= delta
			if _state_time <= 0.0:
				_resolve_divine_annihilation()
		State.DEAD:
			pass


func _handle_free_inputs() -> void:
	if Input.is_action_just_pressed(&"ultimate") and ultimate_cooldown <= 0.0:
		_begin_divine_annihilation()
	elif Input.is_action_just_pressed(&"ability_1") and blessing_cooldown <= 0.0:
		_cast_roaring_blessing()
	elif Input.is_action_just_pressed(&"ability_2") and surge_cooldown <= 0.0:
		_begin_explosive_surge()
	elif Input.is_action_just_pressed(&"evade") and flashstep_cooldown <= 0.0:
		_begin_flashstep()
	elif Input.is_action_just_pressed(&"signature"):
		_begin_thunder_dash()
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
	_begin_dart()
	return true


func _update_movement() -> void:
	var move_input := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	var speed_scale := 1.0
	match _state:
		State.DART_STARTUP:
			speed_scale = 0.72
		State.DART_RECOVERY:
			speed_scale = 0.88
		State.DASH_CHARGE:
			speed_scale = 0.42
		State.DASH_ACTIVE, State.FLASHSTEP:
			velocity = _dash_direction * _dash_speed
			return
		State.DASH_RECOVERY, State.BLESSING_RECOVERY, State.SURGE_RECOVERY:
			speed_scale = 0.72
		State.SURGE_STARTUP:
			speed_scale = 0.32
		State.ULTIMATE_STARTUP:
			speed_scale = 0.08
		State.ULTIMATE_RECOVERY:
			speed_scale = 0.46
		State.STAGGER, State.DEAD:
			speed_scale = 0.0
	velocity = move_input * MOVE_SPEED * speed_scale + _knockback_velocity
	_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, 42.0)


func _begin_dart() -> void:
	_state_time = 0.055
	audio_requested.emit(&"sniff_dart_charge", float(blessing) / float(MAX_BLESSING))
	_set_state(State.DART_STARTUP)


func _spawn_dart() -> void:
	var dart := SniffLightningDart.new()
	dart.configure(self, aim_direction, blessing)
	get_parent().add_child(dart)
	dart.global_position = global_position + aim_direction * 42.0
	lightning_arc_requested.emit(global_position - aim_direction * 18.0, dart.global_position + aim_direction * 22.0, 0.35)
	audio_requested.emit(&"sniff_dart", float(blessing) / float(MAX_BLESSING))
	_state_time = 0.105
	_set_state(State.DART_RECOVERY)


func on_lightning_dart_hit(target: Node2D, at: Vector2, direction: Vector2, blessing_snapshot: int) -> void:
	if not is_instance_valid(target) or not target.is_in_group(&"enemies"):
		return
	var packet := DamagePacket.sniff_dart(self, blessing_snapshot)
	var dealt := DamageResolver.apply_with_result(target, packet, direction)
	if dealt <= 0.0:
		return
	gain_blessing(1)
	effect_requested.emit(&"sniff_strike", at, direction, 0.82)
	combat_impact.emit(at, direction, packet, 0.34 + float(blessing_snapshot) * 0.025)
	lightning_arc_requested.emit(at - direction * 48.0, at, 0.48)

	var should_chain := _overcharge_time > 0.0 or _rng.randf() <= chain_chance
	if not should_chain:
		return
	var candidates: Array[Node2D] = []
	for enemy_node: Node in get_tree().get_nodes_in_group(&"enemies"):
		if not enemy_node is Node2D or enemy_node == target:
			continue
		var enemy := enemy_node as Node2D
		if target.global_position.distance_to(enemy.global_position) <= 265.0 and _target_is_alive(enemy):
			candidates.append(enemy)
	candidates.sort_custom(func(left: Node2D, right: Node2D) -> bool:
		return target.global_position.distance_squared_to(left.global_position) < target.global_position.distance_squared_to(right.global_position)
	)
	var chain_limit := 2 if blessing_snapshot >= 7 else 1
	var previous := target
	for chain_index: int in mini(chain_limit, candidates.size()):
		var chained_target := candidates[chain_index]
		var chain_direction := (chained_target.global_position - previous.global_position).normalized()
		var chain_packet := DamagePacket.sniff_dart(self, blessing_snapshot, chain_index + 1)
		var chain_dealt := DamageResolver.apply_with_result(chained_target, chain_packet, chain_direction)
		if chain_dealt > 0.0:
			gain_blessing(1)
			lightning_arc_requested.emit(previous.global_position, chained_target.global_position, 0.72 - float(chain_index) * 0.12)
			combat_impact.emit(chained_target.global_position, chain_direction, chain_packet, 0.28)
		previous = chained_target
	audio_requested.emit(&"sniff_chain", clampf(float(candidates.size()) / 2.0, 0.35, 1.0))


func _begin_thunder_dash() -> void:
	_dash_charge = 0.0
	_dash_direction = aim_direction
	audio_requested.emit(&"sniff_dash_charge", 0.25)
	_set_state(State.DASH_CHARGE)


func _release_thunder_dash() -> void:
	var move_input := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	_dash_direction = move_input.normalized() if not move_input.is_zero_approx() else aim_direction
	aim_direction = _dash_direction
	_dash_spent = mini(3, blessing)
	spend_blessing(_dash_spent)
	var distance := lerpf(DASH_MIN_DISTANCE, DASH_MAX_DISTANCE, CombatMath.shaped_charge(_dash_charge))
	_state_time = lerpf(0.16, 0.27, _dash_charge)
	_dash_speed = distance / _state_time
	_hit_target_ids.clear()
	_set_attack_radius(48.0)
	_attack_area.monitoring = true
	_set_enemy_phasing(true)
	_invulnerable_time = maxf(_invulnerable_time, _state_time * 0.72)
	effect_requested.emit(&"sniff_dash", global_position, _dash_direction, 1.0 + _dash_charge * 0.35)
	audio_requested.emit(&"sniff_dash", _dash_charge)
	lightning_arc_requested.emit(global_position, global_position + _dash_direction * distance, 0.42 + _dash_charge * 0.30)
	_set_state(State.DASH_ACTIVE)


func _apply_dash_hits() -> void:
	var packet := DamagePacket.sniff_dash(self, _dash_charge, _dash_spent)
	_apply_traversal_hits(packet, true)


func _cast_roaring_blessing() -> void:
	_apply_self_cost(MAX_HEALTH * 0.08)
	gain_blessing(4)
	_overcharge_time = 3.8
	blessing_cooldown = 8.0
	thunder_burst_requested.emit(global_position, 92.0, 0.48, false)
	effect_requested.emit(&"sniff_blessing", global_position, aim_direction, 1.25)
	audio_requested.emit(&"sniff_blessing", 0.82)
	announcement_requested.emit("ROARING BLESSING")
	_state_time = 0.24
	_set_state(State.BLESSING_RECOVERY)
	stats_changed.emit()


func _begin_explosive_surge() -> void:
	_surge_spent = blessing
	spend_blessing(_surge_spent)
	_apply_self_cost(MAX_HEALTH * 0.10)
	_surge_radius = SURGE_BASE_RADIUS + SURGE_STACK_RADIUS * float(_surge_spent)
	_set_attack_radius(_surge_radius)
	_attack_area.monitoring = true
	surge_cooldown = 7.5
	_state_time = 0.27
	audio_requested.emit(&"sniff_surge_charge", float(_surge_spent) / float(MAX_BLESSING))
	_set_state(State.SURGE_STARTUP)
	stats_changed.emit()


func _resolve_explosive_surge() -> void:
	var packet := DamagePacket.sniff_surge(self, _surge_spent)
	_hit_target_ids.clear()
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
		if dealt > 0.0:
			combat_impact.emit(target.global_position, direction, packet, clampf(0.48 + float(_surge_spent) * 0.05, 0.0, 1.0))
			lightning_arc_requested.emit(global_position, target.global_position, 0.55 + float(_surge_spent) * 0.035)
	_attack_area.monitoring = false
	thunder_burst_requested.emit(global_position, _surge_radius, float(_surge_spent) / float(MAX_BLESSING), false)
	audio_requested.emit(&"sniff_surge", float(_surge_spent) / float(MAX_BLESSING))
	_state_time = 0.43
	_set_state(State.SURGE_RECOVERY)


func _begin_flashstep() -> void:
	var move_input := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	_dash_direction = move_input.normalized() if not move_input.is_zero_approx() else aim_direction
	var distance := 158.0
	_state_time = 0.13
	_dash_speed = distance / _state_time
	_hit_target_ids.clear()
	_set_attack_radius(43.0)
	_attack_area.monitoring = true
	_set_enemy_phasing(true)
	_invulnerable_time = maxf(_invulnerable_time, 0.23)
	flashstep_cooldown = FLASHSTEP_COOLDOWN
	effect_requested.emit(&"sniff_dash", global_position, _dash_direction, 0.94)
	lightning_arc_requested.emit(global_position, global_position + _dash_direction * distance, 0.56)
	audio_requested.emit(&"sniff_step", 0.55)
	_set_state(State.FLASHSTEP)
	stats_changed.emit()


func _apply_flashstep_hits() -> void:
	_apply_traversal_hits(DamagePacket.sniff_flashstep(self, blessing), false)


func _apply_traversal_hits(packet: DamagePacket, reward_blessing: bool) -> void:
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
		if reward_blessing:
			gain_blessing(1)
		combat_impact.emit(target.global_position, direction, packet, clampf(packet.health_damage / 62.0, 0.24, 0.92))
		lightning_arc_requested.emit(global_position - direction * 36.0, target.global_position, 0.62)


func _begin_divine_annihilation() -> void:
	_ultimate_snapshot = blessing
	_ultimate_crowned = blessing >= MAX_BLESSING
	spend_blessing(blessing)
	_apply_self_cost(MAX_HEALTH * 0.15)
	ultimate_cooldown = 20.0
	_state_time = 0.68
	if _ultimate_crowned:
		_invulnerable_time = maxf(_invulnerable_time, 1.72)
	audio_requested.emit(&"sniff_ultimate_charge", float(_ultimate_snapshot) / float(MAX_BLESSING))
	announcement_requested.emit("DIVINE ANNIHILATION")
	_set_state(State.ULTIMATE_STARTUP)
	stats_changed.emit()


func _resolve_divine_annihilation() -> void:
	var packet := DamagePacket.sniff_annihilation(self, _ultimate_snapshot)
	var targets: Array[Node2D] = []
	for enemy_node: Node in get_tree().get_nodes_in_group(&"enemies"):
		if enemy_node is Node2D and _target_is_alive(enemy_node as Node2D):
			var target := enemy_node as Node2D
			if global_position.distance_to(target.global_position) <= ULTIMATE_RADIUS:
				targets.append(target)
	targets.sort_custom(func(left: Node2D, right: Node2D) -> bool:
		return global_position.distance_squared_to(left.global_position) < global_position.distance_squared_to(right.global_position)
	)
	var arc_origin := global_position
	for target: Node2D in targets:
		var direction := (target.global_position - global_position).normalized()
		var dealt := DamageResolver.apply_with_result(target, packet, direction)
		if dealt > 0.0:
			lightning_arc_requested.emit(arc_origin, target.global_position, 1.0)
			combat_impact.emit(target.global_position, direction, packet, 1.0)
			arc_origin = target.global_position
	thunder_burst_requested.emit(global_position, ULTIMATE_RADIUS, 1.0, true)
	audio_requested.emit(&"sniff_ultimate", 1.0)
	_state_time = 0.72
	_set_state(State.ULTIMATE_RECOVERY)
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
	if resolve <= 0.0 and _state != State.ULTIMATE_STARTUP:
		resolve = MAX_RESOLVE * 0.42
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


func heal(amount: float) -> void:
	if amount <= 0.0 or _state == State.DEAD:
		return
	health = minf(MAX_HEALTH, health + amount)
	stats_changed.emit()


func gain_blessing(amount: int) -> void:
	if amount <= 0 or _state == State.DEAD:
		return
	var before := blessing
	blessing = clampi(blessing + amount, 0, MAX_BLESSING)
	if blessing == MAX_BLESSING and before < MAX_BLESSING:
		audio_requested.emit(&"sniff_crowned", 1.0)
		announcement_requested.emit("THUNDER CROWNED")
	stats_changed.emit()


func spend_blessing(amount: int) -> void:
	blessing = maxi(0, blessing - maxi(0, amount))
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


func get_dash_charge_ratio() -> float:
	return _dash_charge if _state == State.DASH_CHARGE else 0.0


func is_dash_charging() -> bool:
	return _state == State.DASH_CHARGE


func get_state_label() -> String:
	match _state:
		State.DART_STARTUP, State.DART_RECOVERY:
			return "Dart"
		State.DASH_CHARGE:
			return "Charging"
		State.DASH_ACTIVE, State.DASH_RECOVERY:
			return "Thunder Dash"
		State.BLESSING_RECOVERY:
			return "Overcharged"
		State.SURGE_STARTUP, State.SURGE_RECOVERY:
			return "Surge"
		State.FLASHSTEP:
			return "Flashstep"
		State.ULTIMATE_STARTUP:
			return "Annihilating"
		State.ULTIMATE_RECOVERY:
			return "Afterglow"
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

	if _state == State.DASH_CHARGE:
		var distance := lerpf(DASH_MIN_DISTANCE, DASH_MAX_DISTANCE, CombatMath.shaped_charge(_dash_charge))
		draw_line(Vector2.ZERO, facing * distance, Color(0.25, 0.86, 1.0, 0.24), 16.0, true)
		draw_line(Vector2.ZERO, facing * distance, Color(1.0, 0.91, 0.35, 0.84), 3.0, true)
	if _state == State.SURGE_STARTUP:
		draw_circle(Vector2.ZERO, _surge_radius, Color(0.10, 0.72, 0.96, 0.09))
		draw_arc(Vector2.ZERO, _surge_radius, 0.0, TAU, 72, Color(0.94, 0.86, 0.25, 0.76), 3.0, true)
	if _state == State.ULTIMATE_STARTUP:
		var pulse := 0.72 + sin(_visual_time * 22.0) * 0.18
		draw_circle(Vector2.ZERO, ULTIMATE_RADIUS, Color(0.18, 0.75, 1.0, 0.035 * pulse))
		draw_arc(Vector2.ZERO, ULTIMATE_RADIUS, 0.0, TAU, 120, Color(0.95, 0.84, 0.22, 0.48 * pulse), 5.0, true)
	if _invulnerable_time > 0.0:
		draw_arc(Vector2.ZERO, 35.0, _visual_time * 5.0, _visual_time * 5.0 + PI * 1.55, 30, Color(0.78, 0.96, 1.0, 0.88), 4.0, true)
	_draw_debug_attack()


func _draw_debug_attack() -> void:
	if not debug_draw_enabled or not _attack_area.monitoring:
		return
	var circle := _attack_shape.shape as CircleShape2D
	draw_circle(Vector2.ZERO, circle.radius, Color(0.12, 0.72, 1.0, 0.09))
	draw_arc(Vector2.ZERO, circle.radius, 0.0, TAU, 72, Color(1.0, 0.86, 0.30, 0.74), 2.0, true)