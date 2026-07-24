class_name NadPlayer
extends CharacterBody2D


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
var _invulnerable_time := 0.0
var _knockback_velocity := Vector2.ZERO
var _attack_area: Area2D
var _attack_shape: CollisionShape2D
var _attack_resolved := false
var _anchors: Array[TerrainAnchor] = []
var _visual_time := 0.0


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
	anchor_cooldown = maxf(0.0, anchor_cooldown - delta)
	cascade_cooldown = maxf(0.0, cascade_cooldown - delta)
	fold_cooldown = maxf(0.0, fold_cooldown - delta)
	ultimate_cooldown = maxf(0.0, ultimate_cooldown - delta)
	_invulnerable_time = maxf(0.0, _invulnerable_time - delta)
	resolve = minf(MAX_RESOLVE, resolve + delta * 5.8)
	mana = minf(MAX_MANA, mana + delta * 13.0)
	_anchors = _anchors.filter(func(anchor: TerrainAnchor) -> bool: return is_instance_valid(anchor))


func _update_buffers(delta: float) -> void:
	_primary_buffer = maxf(0.0, _primary_buffer - delta)
	if _state != State.FREE and Input.is_action_just_pressed(&"primary"):
		_primary_buffer = INPUT_BUFFER_DURATION


func _update_aim() -> void:
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
			_mantle_charge = minf(1.0, _mantle_charge + delta / 1.05)
			_mantle_radius = lerpf(MANTLE_MIN_RADIUS, MANTLE_MAX_RADIUS, CombatMath.shaped_charge(_mantle_charge))
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
				distortion_requested.emit(global_position, 62.0, 0.48, &"fold")
				_state_time = 0.08
				_set_state(State.MANTLE_RECOVERY)
		State.ULTIMATE_STARTUP:
			_state_time -= delta
			if _state_time <= 0.0:
				_resolve_arcane_conduit()
		State.DEAD:
			pass


func _handle_free_inputs() -> void:
	if Input.is_action_just_pressed(&"ultimate") and ultimate_cooldown <= 0.0 and mana >= CONDUIT_COST:
		_begin_arcane_conduit()
	elif Input.is_action_just_pressed(&"ability_1") and anchor_cooldown <= 0.0:
		_cast_terrain_anchor()
	elif Input.is_action_just_pressed(&"ability_2") and cascade_cooldown <= 0.0 and mana >= CASCADE_COST:
		_begin_mental_cascade()
	elif Input.is_action_just_pressed(&"evade") and fold_cooldown <= 0.0:
		_begin_fold_space()
	elif Input.is_action_just_pressed(&"signature") and mana >= MANTLE_COST:
		_begin_eldritch_mantle()
	elif (Input.is_action_just_pressed(&"primary") or _primary_buffer > 0.0) and mana >= FORESEE_COST:
		_primary_buffer = 0.0
		_begin_foresee()


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
	velocity = move_input * MOVE_SPEED * speed_scale + _knockback_velocity
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
	nearest.call(&"apply_mental_focus", 1, 7.0)
	nearest.call(&"apply_control_lock", 0.24 + 0.05 * float(focus_before))
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


func _release_mantle() -> void:
	_set_attack_circle(_mantle_radius, _mantle_center_local)
	_attack_resolved = false
	_attack_area.monitoring = true
	_state_time = 0.09
	distortion_requested.emit(global_position + _mantle_center_local, _mantle_radius, _mantle_charge, &"mantle")
	audio_requested.emit(&"nad_mantle", _mantle_charge)
	_set_state(State.MANTLE_ACTIVE)


func _apply_mantle() -> void:
	_attack_resolved = true
	var lock_duration := lerpf(1.60, 3.80, CombatMath.shaped_charge(_mantle_charge))
	var packet := DamagePacket.nad_mantle(self, _mantle_charge)
	for hurtbox: Area2D in _attack_area.get_overlapping_areas():
		var target := hurtbox.get_parent() as Node2D
		if not is_instance_valid(target) or not target.is_in_group(&"enemies"):
			continue
		target.call(&"apply_mental_focus", 2, 8.0)
		target.call(&"apply_control_lock", lock_duration)
		var direction := (target.global_position - (global_position + _mantle_center_local)).normalized()
		var dealt := DamageResolver.apply_with_result(target, packet, direction)
		if dealt > 0.0:
			combat_impact.emit(target.global_position, direction, packet, 0.48 + _mantle_charge * 0.42)
			mind_link_requested.emit(global_position + _mantle_center_local, target.global_position, 0.62)


func _cast_terrain_anchor() -> void:
	_anchors = _anchors.filter(func(anchor: TerrainAnchor) -> bool: return is_instance_valid(anchor))
	if _anchors.size() >= 3:
		_detonate_anchors()
		return
	if not _spend_mana(ANCHOR_COST):
		return
	var anchor := TerrainAnchor.new()
	anchor.configure(self)
	get_parent().add_child(anchor)
	anchor.global_position = global_position + aim_direction * 265.0
	_anchors.append(anchor)
	anchor_cooldown = 0.75
	distortion_requested.emit(anchor.global_position, TerrainAnchor.RADIUS, 0.35, &"anchor_place")
	audio_requested.emit(&"nad_anchor_place", float(_anchors.size()) / 3.0)
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


func on_anchor_detonated(at: Vector2, hit_count: int) -> void:
	distortion_requested.emit(at, TerrainAnchor.RADIUS, clampf(float(hit_count) / 3.0, 0.38, 1.0), &"anchor_detonate")


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
	_set_attack_cone(CASCADE_REACH, CASCADE_HALF_WIDTH, aim_direction)
	_attack_resolved = false
	_attack_area.monitoring = true
	_state_time = 0.09
	distortion_requested.emit(global_position + aim_direction * CASCADE_REACH * 0.52, CASCADE_REACH * 0.55, 0.68, &"cascade")
	audio_requested.emit(&"nad_cascade", 0.72)
	_set_state(State.CASCADE_ACTIVE)


func _apply_cascade() -> void:
	_attack_resolved = true
	for hurtbox: Area2D in _attack_area.get_overlapping_areas():
		var target := hurtbox.get_parent() as Node2D
		if not is_instance_valid(target) or not target.is_in_group(&"enemies"):
			continue
		var focus_before := _get_target_focus(target)
		var was_locked := bool(target.call(&"is_control_locked"))
		target.call(&"apply_mental_focus", 1, 8.0)
		if was_locked:
			target.call(&"extend_control_lock", 0.55 + 0.10 * float(focus_before), 6.0)
		var direction := (target.global_position - global_position).normalized()
		var packet := DamagePacket.nad_cascade(self, focus_before)
		var dealt := DamageResolver.apply_with_result(target, packet, direction)
		if dealt > 0.0:
			combat_impact.emit(target.global_position, direction, packet, 0.48 + 0.06 * float(focus_before))
			mind_link_requested.emit(global_position, target.global_position, 0.68)


func _begin_fold_space() -> void:
	var move_input := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	_fold_direction = move_input.normalized() if not move_input.is_zero_approx() else aim_direction
	var distance := 168.0
	_state_time = 0.12
	_fold_speed = distance / _state_time
	_invulnerable_time = 0.22
	fold_cooldown = 2.8
	collision_mask = 4
	distortion_requested.emit(global_position, 58.0, 0.46, &"fold")
	audio_requested.emit(&"nad_fold", 0.62)
	_set_state(State.FOLD_SPACE)
	stats_changed.emit()


func _begin_arcane_conduit() -> void:
	if not _spend_mana(CONDUIT_COST):
		return
	ultimate_cooldown = 22.0
	_state_time = 0.64
	_invulnerable_time = 1.80
	_set_attack_circle(CONDUIT_RADIUS, Vector2.ZERO)
	_attack_area.monitoring = true
	audio_requested.emit(&"nad_ultimate_charge", 1.0)
	announcement_requested.emit("ARCANE CONDUIT")
	_set_state(State.ULTIMATE_STARTUP)
	stats_changed.emit()


func _resolve_arcane_conduit() -> void:
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
		target.call(&"apply_mental_focus", 1, 9.0)
		target.call(&"apply_control_lock", 2.80 + 0.16 * float(focus_before) if was_locked else 0.75)
		var direction := (target.global_position - global_position).normalized()
		var packet := DamagePacket.nad_conduit(self, focus_before, was_locked)
		var dealt := DamageResolver.apply_with_result(target, packet, direction)
		if dealt > 0.0:
			combat_impact.emit(target.global_position, direction, packet, 1.0 if was_locked else 0.62)
			mind_link_requested.emit(global_position, target.global_position, 1.0 if was_locked else 0.66)
	_attack_area.monitoring = false
	distortion_requested.emit(global_position, CONDUIT_RADIUS, 1.0, &"conduit")
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
		resolve = MAX_RESOLVE * 0.44
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
	health = minf(MAX_HEALTH, health + amount)
	stats_changed.emit()


func restore_mana(amount: float) -> void:
	if amount <= 0.0 or _state == State.DEAD:
		return
	mana = minf(MAX_MANA, mana + amount)
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