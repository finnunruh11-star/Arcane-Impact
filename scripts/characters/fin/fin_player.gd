class_name FinPlayer
extends CharacterBody2D


signal combat_impact(at: Vector2, direction: Vector2, packet: DamagePacket, intensity: float)
signal effect_requested(effect_id: StringName, at: Vector2, direction: Vector2, size_scale: float)
signal audio_requested(cue: StringName, power: float)
signal parry_impact(at: Vector2, direction: Vector2, perfect: bool, power: float)
signal stats_changed
signal state_changed(label: String)
signal form_changed(form: int, label: String)
signal announcement_requested(text: String)
signal defeated

enum Form {
	NIGHTBLADE,
	ARBALEST,
	HUNTSMAN,
	ARTIFICER,
}

enum Potion {
	MENDING,
	QUICKSILVER,
	SHADE,
	VOLATILE,
}

enum State {
	FREE,
	PRIMARY_STARTUP,
	PRIMARY_ACTIVE,
	PRIMARY_RECOVERY,
	SIGNATURE_CHARGE,
	SIGNATURE_ACTIVE,
	SIGNATURE_RECOVERY,
	ABILITY_RECOVERY,
	SHADOW_DASH,
	PARRY,
	FORM_SWITCH,
	STAGGER,
	DEAD,
}

const MAX_HEALTH := 245.0
const MAX_RESOLVE := 175.0
const MAX_WARD := 52.0
const MOVE_SPEED := 310.0
const MAX_PIERCE_MARKS := 5
const FORM_HOLD_THRESHOLD := 0.24
const PERFECT_PARRY_WINDOW := 0.18
const READIED_PARRY_WINDOW := 0.32
const CROSSBOW_RELOAD_TIME := 2.15
const DAGGER_CHARGE_TIME := 3.4
const POTION_CHARGE_TIME := 11.0
const SMOKE_CHARGE_TIME := 10.0

const FORM_NAMES := ["NIGHTBLADE", "ARBALEST", "HUNTSMAN", "ARTIFICER"]
const FORM_SUBTITLES := ["VEIL / BACKSTAB", "BRACE / BREACH", "TRACK / BIND", "BREW / COMPRESS"]
const FORM_ACCENTS := [Color("8fd6c5"), Color("e3a64b"), Color("8fc46c"), Color("52c7bd")]
const PRIMARY_NAMES := ["TWIN DAGGERS", "HAND CROSSBOW", "HUNTER BOW", "MUTIVARG'S ROD"]
const SIGNATURE_NAMES := ["MIND PIERCE", "BREACH BOLT", "POWER DRAW", "MUTIVARG FIELD"]
const ABILITY_1_NAMES := ["UMBRAL VEIL", "QUICK CRANK", "SHADOW BIND", "POTIONS"]
const ABILITY_2_NAMES := ["SHADOW LUNGE", "SCATTERBOLT", "THROWING DAGGER", "SMOKE BOMB"]

var health := MAX_HEALTH
var resolve := MAX_RESOLVE
var ward := 0.0
var aim_direction := Vector2.RIGHT
var debug_draw_enabled := false

var veil_cooldown := 0.0
var shadow_lunge_cooldown := 0.0
var quick_crank_cooldown := 0.0
var scatterbolt_cooldown := 0.0
var shadow_bind_cooldown := 0.0
var mutivarg_cooldown := 0.0

var _form := Form.NIGHTBLADE
var _state := State.FREE
var _state_time := 0.0
var _active_action: StringName = &""
var _using_gamepad := false
var _visual_time := 0.0
var _primary_buffer := 0.0
var _combo_stage := 0
var _combo_buffered := false
var _signature_charge := 0.0
var _signature_charge_duration := 1.0
var _attack_area: Area2D
var _attack_shape: CollisionShape2D
var _attack_resolved := false
var _hit_target_ids: Dictionary = {}
var _knockback_velocity := Vector2.ZERO
var _dash_direction := Vector2.RIGHT
var _dash_speed := 0.0
var _invulnerable_time := 0.0
var _parry_elapsed := 0.0
var _readied_parry_source: Node2D

var _form_input_held := false
var _form_hold_time := 0.0
var _form_wheel_open := false
var _form_preview := Form.NIGHTBLADE

var _veil_time := 0.0
var _smoke_veil_time := 0.0
var _haste_time := 0.0
var _brace_time := 0.0
var _crossbow_loaded := true
var _crossbow_reload := 0.0
var _throwing_daggers := 3
var _dagger_recharge := 0.0
var _potions := 3
var _potion_recharge := 0.0
var _smoke_bombs := 2
var _smoke_recharge := 0.0
var _last_potion := Potion.MENDING
var _traps: Array[FinShadowTrap] = []


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
	hurt_circle.radius = 32.0
	hurt_shape.shape = hurt_circle
	hurt_shape.position = Vector2(0.0, 4.0)
	hurtbox.add_child(hurt_shape)

	_attack_area = Area2D.new()
	_attack_area.name = "FinAttackArea"
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
	_update_form_input(delta)
	_update_buffers(delta)
	_update_state(delta)
	_update_movement()
	move_and_slide()
	_clamp_to_arena()
	_visual_time += delta
	queue_redraw()


func _tick_timers(delta: float) -> void:
	veil_cooldown = maxf(0.0, veil_cooldown - delta)
	shadow_lunge_cooldown = maxf(0.0, shadow_lunge_cooldown - delta)
	quick_crank_cooldown = maxf(0.0, quick_crank_cooldown - delta)
	scatterbolt_cooldown = maxf(0.0, scatterbolt_cooldown - delta)
	shadow_bind_cooldown = maxf(0.0, shadow_bind_cooldown - delta)
	mutivarg_cooldown = maxf(0.0, mutivarg_cooldown - delta)
	_invulnerable_time = maxf(0.0, _invulnerable_time - delta)
	_veil_time = maxf(0.0, _veil_time - delta)
	_smoke_veil_time = maxf(0.0, _smoke_veil_time - delta)
	_haste_time = maxf(0.0, _haste_time - delta)
	_brace_time = maxf(0.0, _brace_time - delta)
	resolve = minf(MAX_RESOLVE, resolve + delta * 5.5)
	ward = maxf(0.0, ward - delta * 0.45)
	_tick_crossbow_reload(delta)
	_tick_charge_resources(delta)
	_traps = _traps.filter(func(trap: FinShadowTrap) -> bool: return is_instance_valid(trap))


func _tick_crossbow_reload(delta: float) -> void:
	if _crossbow_loaded or _crossbow_reload <= 0.0:
		return
	_crossbow_reload = maxf(0.0, _crossbow_reload - delta)
	if _crossbow_reload <= 0.0:
		_crossbow_loaded = true
		audio_requested.emit(&"fin_reload", 0.72)
		stats_changed.emit()


func _tick_charge_resources(delta: float) -> void:
	if _throwing_daggers < 3:
		_dagger_recharge += delta
		if _dagger_recharge >= DAGGER_CHARGE_TIME:
			_dagger_recharge -= DAGGER_CHARGE_TIME
			_throwing_daggers += 1
			stats_changed.emit()
	else:
		_dagger_recharge = 0.0
	if _potions < 3:
		_potion_recharge += delta
		if _potion_recharge >= POTION_CHARGE_TIME:
			_potion_recharge -= POTION_CHARGE_TIME
			_potions += 1
			stats_changed.emit()
	else:
		_potion_recharge = 0.0
	if _smoke_bombs < 2:
		_smoke_recharge += delta
		if _smoke_recharge >= SMOKE_CHARGE_TIME:
			_smoke_recharge -= SMOKE_CHARGE_TIME
			_smoke_bombs += 1
			stats_changed.emit()
	else:
		_smoke_recharge = 0.0


func _update_buffers(delta: float) -> void:
	_primary_buffer = maxf(0.0, _primary_buffer - delta)
	if _state != State.FREE and Input.is_action_just_pressed(&"primary"):
		_primary_buffer = 0.12
		if _state == State.PRIMARY_RECOVERY and _form == Form.NIGHTBLADE:
			_combo_buffered = true


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


func _update_form_input(delta: float) -> void:
	if _state == State.DEAD or _state == State.STAGGER:
		_cancel_form_input()
		return
	if Input.is_action_just_pressed(&"ultimate") and _state == State.FREE:
		_form_input_held = true
		_form_hold_time = 0.0
		_form_preview = _form
	if _form_input_held and Input.is_action_pressed(&"ultimate"):
		_form_hold_time += delta
		if _form_hold_time >= FORM_HOLD_THRESHOLD:
			_form_wheel_open = true
			_form_preview = get_form_for_direction(_get_form_selection_direction())
	if _form_input_held and Input.is_action_just_released(&"ultimate"):
		if _form_wheel_open:
			select_form(_form_preview)
		else:
			cycle_form()
		_cancel_form_input()


func _cancel_form_input() -> void:
	_form_input_held = false
	_form_hold_time = 0.0
	_form_wheel_open = false


func _get_form_selection_direction() -> Vector2:
	var move_input := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	return move_input.normalized() if not move_input.is_zero_approx() else aim_direction


func get_form_for_direction(direction: Vector2) -> int:
	if direction.is_zero_approx():
		return _form
	if absf(direction.y) > absf(direction.x):
		return Form.NIGHTBLADE if direction.y < 0.0 else Form.HUNTSMAN
	return Form.ARBALEST if direction.x > 0.0 else Form.ARTIFICER


func cycle_form() -> void:
	select_form((_form + 1) % Form.size())


func select_form(next_form: int) -> void:
	var selected := clampi(next_form, Form.NIGHTBLADE, Form.ARTIFICER)
	if selected == _form:
		return
	if _form == Form.NIGHTBLADE:
		_veil_time = 0.0
	_form = selected
	_combo_stage = 0
	_combo_buffered = false
	_attack_area.monitoring = false
	_state_time = 0.14
	_set_state(State.FORM_SWITCH)
	form_changed.emit(_form, get_form_label())
	announcement_requested.emit(get_form_label())
	effect_requested.emit(&"fin_switch", global_position, aim_direction, 0.82)
	audio_requested.emit(&"fin_switch", float(_form) / 3.0)
	stats_changed.emit()


func _update_state(delta: float) -> void:
	match _state:
		State.FREE:
			_handle_free_inputs()
		State.PRIMARY_STARTUP:
			_state_time -= delta
			if _state_time <= 0.0:
				_resolve_primary()
		State.PRIMARY_ACTIVE:
			_apply_active_attack_hits()
			_state_time -= delta
			if _state_time <= 0.0:
				_attack_area.monitoring = false
				_state_time = 0.16 if _active_action == &"dagger_primary" else 0.22
				_set_state(State.PRIMARY_RECOVERY)
		State.PRIMARY_RECOVERY:
			_state_time -= delta
			if _state_time <= 0.055 and _combo_buffered and _form == Form.NIGHTBLADE and _combo_stage < 2:
				_combo_buffered = false
				_begin_primary(_combo_stage + 1)
			elif _state_time <= 0.0:
				_combo_stage = 0
				_combo_buffered = false
				_return_to_free_or_buffer()
		State.SIGNATURE_CHARGE:
			_signature_charge = minf(1.0, _signature_charge + delta / _signature_charge_duration)
			if not Input.is_action_pressed(&"signature") or _signature_charge >= 1.0:
				_release_signature()
		State.SIGNATURE_ACTIVE:
			_apply_active_attack_hits()
			_state_time -= delta
			if _state_time <= 0.0:
				_attack_area.monitoring = false
				_state_time = 0.28
				_set_state(State.SIGNATURE_RECOVERY)
		State.SHADOW_DASH:
			_apply_active_attack_hits()
			_state_time -= delta
			if _state_time <= 0.0:
				_attack_area.monitoring = false
				collision_mask = 2 | 4
				_state_time = 0.13
				_set_state(State.ABILITY_RECOVERY)
		State.PARRY:
			_parry_elapsed += delta
			_state_time -= delta
			if _state_time <= 0.0:
				_state_time = 0.09
				_set_state(State.ABILITY_RECOVERY)
		State.SIGNATURE_RECOVERY, State.ABILITY_RECOVERY, State.FORM_SWITCH, State.STAGGER:
			_state_time -= delta
			if _state_time <= 0.0:
				_return_to_free_or_buffer()
		State.DEAD:
			pass


func _return_to_free_or_buffer() -> void:
	if _primary_buffer > 0.0 and _state != State.STAGGER:
		_primary_buffer = 0.0
		_begin_primary(0)
	else:
		_set_state(State.FREE)


func _handle_free_inputs() -> void:
	if _form_input_held:
		return
	if Input.is_action_just_pressed(&"evade"):
		_begin_masterful_parry()
	elif Input.is_action_just_pressed(&"ability_1"):
		_use_ability_1()
	elif Input.is_action_just_pressed(&"ability_2"):
		_use_ability_2()
	elif Input.is_action_just_pressed(&"signature"):
		_begin_signature()
	elif Input.is_action_just_pressed(&"primary") or _primary_buffer > 0.0:
		_primary_buffer = 0.0
		_begin_primary(0)


func _update_movement() -> void:
	var move_input := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	var form_speed := [1.10, 0.84, 1.0, 0.93][_form] as float
	if _haste_time > 0.0:
		form_speed *= 1.22
	if _veil_time > 0.0:
		form_speed *= 1.16
	var state_speed := 1.0
	match _state:
		State.PRIMARY_STARTUP:
			state_speed = 0.72 if _form != Form.ARBALEST else 0.28
		State.PRIMARY_ACTIVE:
			state_speed = 0.42
		State.PRIMARY_RECOVERY:
			state_speed = 0.82
		State.SIGNATURE_CHARGE:
			state_speed = [0.56, 0.14, 0.46, 0.36][_form] as float
		State.SIGNATURE_ACTIVE:
			state_speed = 0.16
		State.SIGNATURE_RECOVERY, State.ABILITY_RECOVERY, State.FORM_SWITCH:
			state_speed = 0.68
		State.PARRY:
			state_speed = 0.28
		State.SHADOW_DASH:
			velocity = _dash_direction * _dash_speed
			return
		State.STAGGER, State.DEAD:
			state_speed = 0.0
	if _form_wheel_open:
		state_speed *= 0.34
	velocity = move_input * MOVE_SPEED * form_speed * state_speed + _knockback_velocity
	_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, 44.0)


func _begin_primary(stage: int) -> void:
	_combo_stage = clampi(stage, 0, 2)
	_hit_target_ids.clear()
	match _form:
		Form.NIGHTBLADE:
			_active_action = &"dagger_primary"
			_state_time = [0.052, 0.065, 0.105][_combo_stage] as float
			audio_requested.emit(&"fin_dagger", float(_combo_stage) / 2.0)
		Form.ARBALEST:
			if not _crossbow_loaded:
				audio_requested.emit(&"fin_empty", 0.35)
				return
			_active_action = &"crossbow_primary"
			_state_time = 0.125
			audio_requested.emit(&"fin_crossbow_brace", 0.35)
		Form.HUNTSMAN:
			_active_action = &"bow_primary"
			_state_time = 0.075
			audio_requested.emit(&"fin_bow_draw", 0.20)
		Form.ARTIFICER:
			_active_action = &"rod_primary"
			_state_time = 0.085
			audio_requested.emit(&"fin_rod", 0.24)
	_set_state(State.PRIMARY_STARTUP)


func _resolve_primary() -> void:
	match _active_action:
		&"dagger_primary":
			_set_attack_rectangle([92.0, 105.0, 138.0][_combo_stage] as float, [32.0, 37.0, 51.0][_combo_stage] as float, aim_direction)
			_attack_resolved = false
			_attack_area.monitoring = true
			_state_time = [0.055, 0.065, 0.085][_combo_stage] as float
			_set_state(State.PRIMARY_ACTIVE)
		&"crossbow_primary":
			_spawn_projectile(FinProjectile.Kind.CROSSBOW_BOLT, aim_direction, 0.18)
			_spend_crossbow_round(CROSSBOW_RELOAD_TIME)
			_apply_crossbow_recoil(235.0)
			effect_requested.emit(&"fin_shot", global_position + aim_direction * 44.0, aim_direction, 0.82)
			audio_requested.emit(&"fin_crossbow", 0.54)
			_state_time = 0.34
			_set_state(State.PRIMARY_RECOVERY)
		&"bow_primary":
			_spawn_projectile(FinProjectile.Kind.ARROW, aim_direction, 0.24)
			effect_requested.emit(&"fin_shot", global_position + aim_direction * 38.0, aim_direction, 0.54)
			audio_requested.emit(&"fin_bow", 0.28)
			_state_time = 0.17
			_set_state(State.PRIMARY_RECOVERY)
		&"rod_primary":
			_spawn_projectile(FinProjectile.Kind.ROD_BOLT, aim_direction, 0.0)
			effect_requested.emit(&"fin_tool", global_position + aim_direction * 42.0, aim_direction, 0.58)
			audio_requested.emit(&"fin_rod", 0.42)
			_state_time = 0.19
			_set_state(State.PRIMARY_RECOVERY)


func _begin_signature() -> void:
	match _form:
		Form.NIGHTBLADE:
			_active_action = &"mind_pierce"
			_signature_charge_duration = 0.82
		Form.ARBALEST:
			if not _crossbow_loaded:
				audio_requested.emit(&"fin_empty", 0.45)
				return
			_active_action = &"breach_bolt"
			_signature_charge_duration = 1.18
			audio_requested.emit(&"fin_crossbow_brace", 0.72)
		Form.HUNTSMAN:
			_active_action = &"power_arrow"
			_signature_charge_duration = 0.96
			audio_requested.emit(&"fin_bow_draw", 0.52)
		Form.ARTIFICER:
			if mutivarg_cooldown > 0.0:
				return
			_active_action = &"mutivarg_field"
			_signature_charge_duration = 1.02
			audio_requested.emit(&"fin_mutivarg_charge", 0.58)
	_signature_charge = 0.0
	_set_state(State.SIGNATURE_CHARGE)


func _release_signature() -> void:
	match _active_action:
		&"mind_pierce":
			_set_attack_rectangle(lerpf(118.0, 162.0, _signature_charge), lerpf(29.0, 42.0, _signature_charge), aim_direction)
			_hit_target_ids.clear()
			_attack_resolved = false
			_attack_area.monitoring = true
			_state_time = 0.085
			effect_requested.emit(&"fin_cut", global_position + aim_direction * 78.0, aim_direction, 0.82 + _signature_charge * 0.52)
			audio_requested.emit(&"fin_mind_pierce", _signature_charge)
			_set_state(State.SIGNATURE_ACTIVE)
		&"breach_bolt":
			_spawn_projectile(FinProjectile.Kind.BREACH_BOLT, aim_direction, _signature_charge)
			_spend_crossbow_round(lerpf(2.75, 3.45, _signature_charge))
			_apply_crossbow_recoil(lerpf(410.0, 710.0, _signature_charge))
			effect_requested.emit(&"fin_shot", global_position + aim_direction * 48.0, aim_direction, 1.25 + _signature_charge * 0.58)
			audio_requested.emit(&"fin_breach", _signature_charge)
			_state_time = 0.52
			_set_state(State.SIGNATURE_RECOVERY)
		&"power_arrow":
			_spawn_projectile(FinProjectile.Kind.POWER_ARROW, aim_direction, _signature_charge)
			effect_requested.emit(&"fin_shot", global_position + aim_direction * 45.0, aim_direction, 0.88 + _signature_charge * 0.44)
			audio_requested.emit(&"fin_bow", 0.52 + _signature_charge * 0.40)
			_state_time = 0.25
			_set_state(State.SIGNATURE_RECOVERY)
		&"mutivarg_field":
			_spawn_field(
				FinField.Kind.MUTIVARG,
				global_position + aim_direction * lerpf(190.0, 315.0, _signature_charge),
				lerpf(120.0, 205.0, _signature_charge),
				_signature_charge
			)
			mutivarg_cooldown = lerpf(5.5, 8.0, _signature_charge)
			effect_requested.emit(&"fin_tool", global_position + aim_direction * 220.0, aim_direction, 1.2 + _signature_charge * 0.6)
			audio_requested.emit(&"fin_mutivarg", _signature_charge)
			_state_time = 0.34
			_set_state(State.SIGNATURE_RECOVERY)
	stats_changed.emit()


func _apply_active_attack_hits() -> void:
	for hurtbox: Area2D in _attack_area.get_overlapping_areas():
		var target := hurtbox.get_parent() as Node2D
		if not is_instance_valid(target) or not target.is_in_group(&"enemies"):
			continue
		var target_id := target.get_instance_id()
		if _hit_target_ids.has(target_id):
			continue
		_hit_target_ids[target_id] = true
		match _active_action:
			&"dagger_primary":
				_resolve_dagger_hit(target)
			&"mind_pierce":
				_resolve_mind_pierce(target)
			&"shadow_lunge":
				_resolve_shadow_lunge_hit(target)


func _resolve_dagger_hit(target: Node2D) -> void:
	var backstab := _is_backstab(target)
	var veil_strike := _veil_time > 0.0
	var damage_scale := (1.48 if backstab else 1.0) * (1.42 if veil_strike else 1.0)
	var packet := DamagePacket.fin_dagger(self, _combo_stage, damage_scale)
	var direction := (target.global_position - global_position).normalized()
	var dealt := DamageResolver.apply_with_result(target, packet, direction)
	if target.has_method(&"apply_pierce_mark"):
		target.call(&"apply_pierce_mark", 2 if _combo_stage == 2 or backstab else 1, 8.0)
	if veil_strike:
		_veil_time = 0.0
	if dealt > 0.0:
		combat_impact.emit(target.global_position, direction, packet, 0.28 + float(_combo_stage) * 0.16 + (0.18 if backstab else 0.0))
		effect_requested.emit(&"fin_cut", target.global_position, direction, 0.72 + float(_combo_stage) * 0.22)
	stats_changed.emit()


func _resolve_mind_pierce(target: Node2D) -> void:
	var marks := int(target.call(&"consume_pierce_marks", MAX_PIERCE_MARKS)) if target.has_method(&"consume_pierce_marks") else 0
	var backstab := _is_backstab(target) or _veil_time > 0.0
	var packet := DamagePacket.fin_mind_pierce(self, _signature_charge, marks, backstab)
	var direction := (target.global_position - global_position).normalized()
	var dealt := DamageResolver.apply_with_result(target, packet, direction)
	if target.has_method(&"apply_control_lock") and (marks >= 3 or backstab):
		target.call(&"apply_control_lock", 0.24 + 0.12 * float(marks))
	_veil_time = 0.0
	if dealt > 0.0:
		combat_impact.emit(target.global_position, direction, packet, clampf(0.48 + _signature_charge * 0.28 + float(marks) * 0.08, 0.0, 1.0))
		effect_requested.emit(&"fin_shadow", target.global_position, direction, 1.0 + float(marks) * 0.12)
	stats_changed.emit()


func _resolve_shadow_lunge_hit(target: Node2D) -> void:
	var backstab := _is_backstab(target) or _veil_time > 0.0
	var packet := DamagePacket.fin_dagger(self, 1, 1.35 if backstab else 1.0)
	var dealt := DamageResolver.apply_with_result(target, packet, _dash_direction)
	if target.has_method(&"apply_pierce_mark"):
		target.call(&"apply_pierce_mark", 2 if backstab else 1, 8.0)
	if dealt > 0.0:
		combat_impact.emit(target.global_position, _dash_direction, packet, 0.48 if backstab else 0.34)
	_veil_time = 0.0


func _use_ability_1() -> void:
	match _form:
		Form.NIGHTBLADE:
			_cast_umbral_veil()
		Form.ARBALEST:
			_cast_quick_crank()
		Form.HUNTSMAN:
			_cast_shadow_bind()
		Form.ARTIFICER:
			use_potion(_choose_potion())


func _use_ability_2() -> void:
	match _form:
		Form.NIGHTBLADE:
			_begin_shadow_lunge()
		Form.ARBALEST:
			_cast_scatterbolt()
		Form.HUNTSMAN:
			_throw_dagger()
		Form.ARTIFICER:
			_throw_smoke_bomb()


func _cast_umbral_veil() -> void:
	if veil_cooldown > 0.0:
		return
	veil_cooldown = 8.0
	_veil_time = 3.4
	_invulnerable_time = maxf(_invulnerable_time, 0.26)
	effect_requested.emit(&"fin_shadow", global_position, aim_direction, 1.15)
	audio_requested.emit(&"fin_veil", 0.72)
	announcement_requested.emit("UMBRAL VEIL")
	_state_time = 0.12
	_set_state(State.ABILITY_RECOVERY)
	stats_changed.emit()


func _begin_shadow_lunge() -> void:
	if shadow_lunge_cooldown > 0.0:
		return
	shadow_lunge_cooldown = 4.2
	_dash_direction = _movement_or_aim_direction()
	aim_direction = _dash_direction
	_state_time = 0.16
	_dash_speed = 245.0 / _state_time
	_invulnerable_time = 0.24
	_hit_target_ids.clear()
	_active_action = &"shadow_lunge"
	_set_attack_rectangle(105.0, 35.0, _dash_direction)
	_attack_area.monitoring = true
	collision_mask = 4
	effect_requested.emit(&"fin_shadow", global_position, _dash_direction, 1.0)
	audio_requested.emit(&"fin_lunge", 0.68)
	_set_state(State.SHADOW_DASH)
	stats_changed.emit()


func _cast_quick_crank() -> void:
	if quick_crank_cooldown > 0.0:
		return
	quick_crank_cooldown = 5.8
	if _crossbow_loaded:
		_brace_time = 3.2
		announcement_requested.emit("STEADY BRACE")
	else:
		_crossbow_reload = minf(_crossbow_reload, 0.38)
		announcement_requested.emit("QUICK CRANK")
	audio_requested.emit(&"fin_quick_crank", 0.72)
	_state_time = 0.21
	_set_state(State.ABILITY_RECOVERY)
	stats_changed.emit()


func _cast_scatterbolt() -> void:
	if scatterbolt_cooldown > 0.0 or not _crossbow_loaded:
		if not _crossbow_loaded:
			audio_requested.emit(&"fin_empty", 0.35)
		return
	scatterbolt_cooldown = 5.4
	for angle_offset: float in [-0.13, 0.0, 0.13]:
		_spawn_projectile(FinProjectile.Kind.CROSSBOW_BOLT, aim_direction.rotated(angle_offset), 0.0)
	_spend_crossbow_round(2.75)
	_apply_crossbow_recoil(330.0)
	effect_requested.emit(&"fin_shot", global_position + aim_direction * 44.0, aim_direction, 1.18)
	audio_requested.emit(&"fin_crossbow", 0.90)
	_state_time = 0.42
	_set_state(State.ABILITY_RECOVERY)
	stats_changed.emit()


func _cast_shadow_bind() -> void:
	_traps = _traps.filter(func(trap: FinShadowTrap) -> bool: return is_instance_valid(trap))
	if shadow_bind_cooldown > 0.0 or _traps.size() >= 2:
		return
	var trap := FinShadowTrap.new()
	trap.configure(self)
	trap.position = get_parent().to_local(global_position + aim_direction * 235.0)
	get_parent().add_child(trap)
	_traps.append(trap)
	shadow_bind_cooldown = 0.72
	effect_requested.emit(&"fin_shadow", trap.global_position, aim_direction, 0.86)
	audio_requested.emit(&"fin_trap", float(_traps.size()) / 2.0)
	_state_time = 0.18
	_set_state(State.ABILITY_RECOVERY)
	stats_changed.emit()


func _throw_dagger() -> void:
	if _throwing_daggers <= 0:
		audio_requested.emit(&"fin_empty", 0.28)
		return
	_throwing_daggers -= 1
	_spawn_projectile(FinProjectile.Kind.THROWING_DAGGER, aim_direction, 0.0)
	effect_requested.emit(&"fin_cut", global_position + aim_direction * 38.0, aim_direction, 0.48)
	audio_requested.emit(&"fin_throw", 0.48)
	_state_time = 0.12
	_set_state(State.ABILITY_RECOVERY)
	stats_changed.emit()


func _choose_potion() -> int:
	var direction := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	if direction.length_squared() < 0.25:
		return Potion.MENDING if health < MAX_HEALTH * 0.68 else Potion.QUICKSILVER
	if absf(direction.y) > absf(direction.x):
		return Potion.MENDING if direction.y < 0.0 else Potion.VOLATILE
	return Potion.QUICKSILVER if direction.x > 0.0 else Potion.SHADE


func use_potion(potion: int) -> bool:
	if _potions <= 0 or _state == State.DEAD:
		return false
	var selected := clampi(potion, Potion.MENDING, Potion.VOLATILE)
	_potions -= 1
	_last_potion = selected
	match selected:
		Potion.MENDING:
			heal(54.0)
			announcement_requested.emit("MENDING DRAUGHT")
		Potion.QUICKSILVER:
			_haste_time = 5.2
			resolve = minf(MAX_RESOLVE, resolve + 24.0)
			announcement_requested.emit("QUICKSILVER TONIC")
		Potion.SHADE:
			_veil_time = maxf(_veil_time, 2.8)
			_invulnerable_time = maxf(_invulnerable_time, 0.18)
			announcement_requested.emit("SHADE TONIC")
		Potion.VOLATILE:
			_spawn_projectile(FinProjectile.Kind.FLASK, aim_direction, 0.0)
			announcement_requested.emit("VOLATILE PHIAL")
	effect_requested.emit(&"fin_tool", global_position, aim_direction, 0.82)
	audio_requested.emit(&"fin_potion", float(selected) / 3.0)
	_state_time = 0.18
	_set_state(State.ABILITY_RECOVERY)
	stats_changed.emit()
	return true


func _throw_smoke_bomb() -> void:
	if _smoke_bombs <= 0:
		return
	_smoke_bombs -= 1
	var at := global_position + aim_direction * 92.0
	_spawn_field(FinField.Kind.ALCHEMICAL_SMOKE, at, 138.0, 0.62)
	receive_smoke_veil(0.42)
	effect_requested.emit(&"fin_smoke", at, aim_direction, 1.32)
	audio_requested.emit(&"fin_smoke", 0.78)
	_state_time = 0.22
	_set_state(State.ABILITY_RECOVERY)
	stats_changed.emit()


func _begin_masterful_parry() -> void:
	_readied_parry_source = _find_readable_windup()
	_parry_elapsed = 0.0
	_state_time = READIED_PARRY_WINDOW
	_active_action = &"masterful_parry"
	effect_requested.emit(&"fin_parry", global_position + aim_direction * 28.0, aim_direction, 0.68)
	audio_requested.emit(&"fin_parry_ready", 0.48 if is_instance_valid(_readied_parry_source) else 0.25)
	_set_state(State.PARRY)


func _find_readable_windup() -> Node2D:
	var best: Node2D
	var best_distance := INF
	for enemy_node: Node in get_tree().get_nodes_in_group(&"enemies"):
		if not enemy_node is Node2D or not enemy_node.has_method(&"is_attack_winding_up"):
			continue
		if not bool(enemy_node.call(&"is_attack_winding_up")):
			continue
		var enemy := enemy_node as Node2D
		var distance := global_position.distance_to(enemy.global_position)
		if distance > 245.0 or distance >= best_distance:
			continue
		if enemy.has_method(&"get_facing_direction"):
			var toward_fin := (global_position - enemy.global_position).normalized()
			if (enemy.call(&"get_facing_direction") as Vector2).dot(toward_fin) < 0.55:
				continue
		best = enemy
		best_distance = distance
	return best


func receive_hit(packet: DamagePacket, incoming_direction: Vector2) -> float:
	if _state == State.DEAD:
		return 0.0
	if _invulnerable_time > 0.0:
		effect_requested.emit(&"fin_shadow", global_position, -incoming_direction, 0.54)
		audio_requested.emit(&"fin_phase", 0.42)
		return 0.0
	var attacker_direction := -incoming_direction.normalized()
	var in_front := aim_direction.dot(attacker_direction) >= cos(deg_to_rad(78.0))
	if _state == State.PARRY and in_front:
		var source_matches_read := is_instance_valid(_readied_parry_source) and packet.source == _readied_parry_source
		var perfect := _parry_elapsed <= PERFECT_PARRY_WINDOW or (source_matches_read and _parry_elapsed <= READIED_PARRY_WINDOW)
		var taken := 0.0 if perfect else packet.health_damage * 0.22
		if is_instance_valid(packet.source):
			if packet.source.has_method(&"apply_pierce_mark"):
				packet.source.call(&"apply_pierce_mark", 2 if perfect else 1, 9.0)
			if perfect and packet.source.has_method(&"apply_control_lock"):
				packet.source.call(&"apply_control_lock", 0.68)
			if perfect and packet.source is Node2D:
				_step_behind_attacker(packet.source as Node2D)
		resolve = minf(MAX_RESOLVE, resolve + packet.resolve_damage * (0.72 if perfect else 0.28))
		_apply_health_damage(taken)
		parry_impact.emit(global_position + attacker_direction * 30.0, attacker_direction, perfect, packet.health_damage)
		effect_requested.emit(&"fin_parry", global_position + attacker_direction * 28.0, attacker_direction, 1.25 if perfect else 0.82)
		audio_requested.emit(&"fin_perfect_parry" if perfect else &"fin_parry", clampf(packet.health_damage / 36.0, 0.25, 1.0))
		_state_time = 0.13
		_set_state(State.ABILITY_RECOVERY)
		stats_changed.emit()
		return taken

	var remaining_damage := packet.health_damage
	if _brace_time > 0.0:
		remaining_damage *= 0.72
	if is_concealed():
		remaining_damage *= 0.64
		_veil_time = 0.0
		_smoke_veil_time = 0.0
	if ward > 0.0:
		var ward_absorb := minf(ward, remaining_damage)
		ward -= ward_absorb
		remaining_damage -= ward_absorb
	_apply_health_damage(remaining_damage)
	resolve = maxf(0.0, resolve - packet.resolve_damage)
	_knockback_velocity += incoming_direction.normalized() * packet.knockback_force
	audio_requested.emit(&"fin_hurt", clampf(packet.health_damage / 38.0, 0.2, 1.0))
	if resolve <= 0.0:
		resolve = MAX_RESOLVE * 0.43
		_attack_area.monitoring = false
		collision_mask = 2 | 4
		_state_time = 0.48
		_set_state(State.STAGGER)
	if health <= 0.0:
		_state = State.DEAD
		velocity = Vector2.ZERO
		defeated.emit()
	stats_changed.emit()
	return remaining_damage


func _step_behind_attacker(attacker: Node2D) -> void:
	var facing := (global_position - attacker.global_position).normalized()
	if attacker.has_method(&"get_facing_direction"):
		facing = attacker.call(&"get_facing_direction") as Vector2
	global_position = attacker.global_position - facing.normalized() * 72.0
	aim_direction = facing
	_invulnerable_time = maxf(_invulnerable_time, 0.16)


func _apply_health_damage(amount: float) -> void:
	health = maxf(0.0, health - maxf(0.0, amount))


func heal(amount: float) -> void:
	if amount <= 0.0 or _state == State.DEAD:
		return
	health = minf(MAX_HEALTH, health + amount)
	stats_changed.emit()


func restore_supplies() -> void:
	_throwing_daggers = 3
	_potions = 3
	_smoke_bombs = 2
	_crossbow_loaded = true
	_crossbow_reload = 0.0
	ward = minf(MAX_WARD, ward + 22.0)
	stats_changed.emit()


func receive_smoke_veil(duration: float) -> void:
	_smoke_veil_time = maxf(_smoke_veil_time, duration)


func _spawn_projectile(kind: int, direction: Vector2, charge: float) -> void:
	var projectile := FinProjectile.new()
	projectile.configure(self, kind as FinProjectile.Kind, direction, charge)
	projectile.position = get_parent().to_local(global_position + direction.normalized() * 42.0)
	get_parent().add_child(projectile)


func on_fin_projectile_hit(
	target: Node2D,
	at: Vector2,
	direction: Vector2,
	kind: int,
	charge: float,
	distance: float
) -> void:
	var packet: DamagePacket
	var mark_count := 0
	var consumed_marks := 0
	match kind:
		FinProjectile.Kind.ARROW, FinProjectile.Kind.POWER_ARROW:
			packet = DamagePacket.fin_arrow(self, charge, distance / 760.0)
			mark_count = 2 if kind == FinProjectile.Kind.POWER_ARROW else 1
		FinProjectile.Kind.THROWING_DAGGER:
			packet = DamagePacket.fin_throwing_dagger(self)
			mark_count = 1
		FinProjectile.Kind.CROSSBOW_BOLT:
			consumed_marks = int(target.call(&"consume_pierce_marks", 2)) if target.has_method(&"consume_pierce_marks") else 0
			packet = DamagePacket.fin_crossbow(self, 0.18, consumed_marks)
		FinProjectile.Kind.BREACH_BOLT:
			consumed_marks = int(target.call(&"consume_pierce_marks", MAX_PIERCE_MARKS)) if target.has_method(&"consume_pierce_marks") else 0
			packet = DamagePacket.fin_crossbow(self, charge, consumed_marks)
		FinProjectile.Kind.ROD_BOLT:
			var current_resolve := float(target.get("resolve")) if target.get("resolve") != null else 0.0
			packet = DamagePacket.fin_rod(self, current_resolve)
			mark_count = 1
		FinProjectile.Kind.FLASK:
			call_deferred(&"_spawn_field", FinField.Kind.ALCHEMICAL_SMOKE, at, 118.0, 0.48)
			return
		_:
			return
	var dealt := DamageResolver.apply_with_result(target, packet, direction)
	if mark_count > 0 and target.has_method(&"apply_pierce_mark"):
		target.call(&"apply_pierce_mark", mark_count, 8.0)
	if kind == FinProjectile.Kind.POWER_ARROW and charge >= 0.78 and target.has_method(&"apply_control_lock"):
		target.call(&"apply_control_lock", 0.38 + charge * 0.28)
	if dealt > 0.0:
		var intensity := clampf(packet.health_damage / 126.0 + float(consumed_marks) * 0.05, 0.18, 1.0)
		combat_impact.emit(at, direction, packet, intensity)
		effect_requested.emit(&"fin_shot" if kind != FinProjectile.Kind.ROD_BOLT else &"fin_tool", at, direction, 0.64 + intensity * 0.58)
	stats_changed.emit()


func on_fin_projectile_expired(kind: int, at: Vector2, _direction: Vector2, _charge: float) -> void:
	if kind == FinProjectile.Kind.FLASK:
		call_deferred(&"_spawn_field", FinField.Kind.ALCHEMICAL_SMOKE, at, 118.0, 0.48)


func _spawn_field(kind: int, at: Vector2, radius: float, power: float) -> void:
	var field := FinField.new()
	field.configure(self, kind as FinField.Kind, radius, power)
	field.position = get_parent().to_local(at)
	get_parent().add_child(field)


func on_fin_field_hit(
	target: Node2D,
	at: Vector2,
	direction: Vector2,
	packet: DamagePacket,
	power: float,
	kind: int
) -> void:
	combat_impact.emit(target.global_position, direction, packet, 0.24 + power * 0.24)
	if kind == FinField.Kind.MUTIVARG:
		effect_requested.emit(&"fin_tool", at, direction, 0.72 + power * 0.34)


func on_shadow_trap_triggered(trap: FinShadowTrap, target: Node2D, at: Vector2) -> void:
	_traps.erase(trap)
	var direction := (target.global_position - at).normalized()
	effect_requested.emit(&"fin_shadow", at, direction, 1.15)
	audio_requested.emit(&"fin_trap_trigger", 0.82)
	stats_changed.emit()


func on_shadow_trap_removed(trap: FinShadowTrap) -> void:
	_traps.erase(trap)
	stats_changed.emit()


func _spend_crossbow_round(reload_time: float) -> void:
	_crossbow_loaded = false
	_crossbow_reload = maxf(0.1, reload_time)
	_brace_time = 0.0
	stats_changed.emit()


func _apply_crossbow_recoil(force: float) -> void:
	var brace_multiplier := 0.34 if _brace_time > 0.0 else 1.0
	_knockback_velocity -= aim_direction * force * brace_multiplier


func _is_backstab(target: Node2D) -> bool:
	if not target.has_method(&"get_facing_direction"):
		return false
	var target_facing := target.call(&"get_facing_direction") as Vector2
	var target_to_fin := (global_position - target.global_position).normalized()
	return target_facing.dot(target_to_fin) <= -0.42


func _movement_or_aim_direction() -> Vector2:
	var move_input := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	return move_input.normalized() if not move_input.is_zero_approx() else aim_direction


func _set_attack_rectangle(reach: float, half_width: float, direction: Vector2) -> void:
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(reach, half_width * 2.0)
	_attack_shape.shape = rectangle
	_attack_shape.position = Vector2(reach * 0.5, 0.0)
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


func is_concealed() -> bool:
	return _veil_time > 0.0 or _smoke_veil_time > 0.0


func is_parrying() -> bool:
	return _state == State.PARRY


func get_readied_parry_target() -> Node2D:
	return _readied_parry_source


func get_form() -> int:
	return _form


func get_form_label() -> String:
	return FORM_NAMES[_form]


func get_form_subtitle() -> String:
	return FORM_SUBTITLES[_form]


func get_form_accent() -> Color:
	return FORM_ACCENTS[_form]


func get_form_preview() -> int:
	return _form_preview


func is_form_wheel_open() -> bool:
	return _form_wheel_open


func get_primary_name() -> String:
	return PRIMARY_NAMES[_form]


func get_signature_name() -> String:
	return SIGNATURE_NAMES[_form]


func get_ability_1_name() -> String:
	return ABILITY_1_NAMES[_form]


func get_ability_2_name() -> String:
	return ABILITY_2_NAMES[_form]


func get_signature_charge_ratio() -> float:
	return _signature_charge if _state == State.SIGNATURE_CHARGE else 0.0


func get_total_pierce_marks() -> int:
	var total := 0
	for enemy: Node in get_tree().get_nodes_in_group(&"enemies"):
		if enemy.has_method(&"get_pierce_marks"):
			total += int(enemy.call(&"get_pierce_marks"))
	return total


func is_crossbow_loaded() -> bool:
	return _crossbow_loaded


func get_crossbow_reload() -> float:
	return _crossbow_reload


func get_throwing_dagger_count() -> int:
	return _throwing_daggers


func get_potion_count() -> int:
	return _potions


func get_smoke_bomb_count() -> int:
	return _smoke_bombs


func get_trap_count() -> int:
	return _traps.size()


func get_last_potion_label() -> String:
	return ["MENDING", "QUICKSILVER", "SHADE", "VOLATILE"][_last_potion]


func get_state_label() -> String:
	match _state:
		State.PRIMARY_STARTUP, State.PRIMARY_ACTIVE, State.PRIMARY_RECOVERY:
			return get_primary_name().capitalize()
		State.SIGNATURE_CHARGE:
			return "Charging %s" % get_signature_name().capitalize()
		State.SIGNATURE_ACTIVE, State.SIGNATURE_RECOVERY:
			return get_signature_name().capitalize()
		State.SHADOW_DASH:
			return "Shadow Lunge"
		State.PARRY:
			return "Reading Intent" if is_instance_valid(_readied_parry_source) else "Masterful Parry"
		State.FORM_SWITCH:
			return "Drawing %s" % get_form_label().capitalize()
		_:
			return State.keys()[_state].capitalize()


func _draw() -> void:
	draw_set_transform(Vector2(0.0, 24.0), 0.0, Vector2(1.38, 0.38))
	draw_circle(Vector2.ZERO, 29.0, Color(0.0, 0.0, 0.0, 0.38))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	var facing := aim_direction
	var right := facing.orthogonal()
	var accent: Color = FORM_ACCENTS[_form]
	var cloak_color := Color("18252a")
	if _form == Form.ARBALEST:
		cloak_color = Color("342a22")
	elif _form == Form.HUNTSMAN:
		cloak_color = Color("233129")
	elif _form == Form.ARTIFICER:
		cloak_color = Color("1b3031")
	var cloak := PackedVector2Array([
		-facing * 32.0 + right * 25.0,
		-facing * 43.0,
		-facing * 32.0 - right * 25.0,
		facing * 12.0 - right * 23.0,
		facing * 26.0,
		facing * 12.0 + right * 23.0,
	])
	draw_colored_polygon(cloak, Color(cloak_color, 0.36 if is_concealed() else 1.0))
	draw_polyline(cloak + PackedVector2Array([cloak[0]]), Color(accent, 0.40 if is_concealed() else 0.92), 3.0, true)
	draw_circle(Vector2.ZERO, 21.0, Color(0.04, 0.07, 0.08, 0.58 if is_concealed() else 1.0))
	draw_circle(facing * 4.0, 12.0, Color("c7d7c9"))
	draw_circle(facing * 10.0 + right * 4.0, 2.8, Color("f0c95a"))
	draw_circle(facing * 10.0 - right * 4.0, 2.8, accent)
	_draw_form_weapon(facing, right, accent)

	if is_concealed():
		for shadow_index: int in 4:
			var shadow_offset := -facing * (18.0 + float(shadow_index) * 11.0) + right * sin(_visual_time * 9.0 + float(shadow_index)) * 7.0
			draw_circle(shadow_offset, 12.0 - float(shadow_index) * 1.8, Color(0.16, 0.47, 0.44, 0.13))
	if _brace_time > 0.0:
		draw_line(-facing * 22.0 + right * 35.0, facing * 42.0 + right * 35.0, Color(0.91, 0.66, 0.28, 0.72), 5.0, true)
	if ward > 0.0:
		draw_arc(Vector2.ZERO, 38.0, _visual_time * 0.8, _visual_time * 0.8 + PI * 1.62, 34, Color(0.34, 0.84, 0.72, 0.52 * ward / MAX_WARD), 4.0, true)
	if _state == State.PARRY:
		var parry_color := Color("f5d263") if is_instance_valid(_readied_parry_source) else accent
		draw_arc(Vector2.ZERO, 48.0, facing.angle() - 0.86, facing.angle() + 0.86, 28, Color(parry_color, 0.88), 5.0, true)
		draw_line(facing * 23.0 - right * 27.0, facing * 48.0 + right * 27.0, Color(parry_color, 0.72), 3.0, true)
	if _state == State.SIGNATURE_CHARGE:
		_draw_signature_preview(facing, right, accent)
	if _form_wheel_open:
		_draw_form_wheel()
	_draw_debug_attack()


func _draw_form_weapon(facing: Vector2, right: Vector2, accent: Color) -> void:
	match _form:
		Form.NIGHTBLADE:
			for side: float in [-1.0, 1.0]:
				var hand := facing * 14.0 + right * side * 17.0
				draw_line(hand, hand + facing * 42.0 + right * side * 3.0, Color("d9e3dc"), 4.0, true)
				draw_line(hand - facing * 4.0, hand + right * side * 11.0, accent, 4.0, true)
		Form.ARBALEST:
			var stock := facing * 12.0 - right * 16.0
			draw_line(stock - facing * 22.0, stock + facing * 55.0, Color("9a6840"), 8.0, true)
			draw_arc(stock + facing * 30.0, 27.0, facing.angle() - 1.18, facing.angle() + 1.18, 24, accent, 5.0, true)
			draw_line(stock + facing * 5.0 - right * 26.0, stock + facing * 5.0 + right * 26.0, Color("d9c38a"), 2.0, true)
			if _crossbow_loaded:
				draw_line(stock + facing * 8.0, stock + facing * 62.0, Color("f0e6c2"), 3.0, true)
		Form.HUNTSMAN:
			var grip := facing * 14.0 - right * 18.0
			draw_arc(grip + facing * 24.0, 40.0, facing.angle() - 1.12, facing.angle() + 1.12, 32, Color("ad7b45"), 5.0, true)
			draw_line(grip + facing * 6.0 - right * 36.0, grip + facing * 6.0 + right * 36.0, Color("d7e2cb"), 2.0, true)
			draw_line(grip - facing * 5.0, grip + facing * 50.0, accent, 3.0, true)
		Form.ARTIFICER:
			var rod_start := -facing * 4.0 - right * 19.0
			var rod_end := facing * 62.0 - right * 19.0
			draw_line(rod_start, rod_end, Color("b99552"), 6.0, true)
			draw_circle(rod_end, 9.0, Color(0.16, 0.63, 0.59, 0.32))
			draw_circle(rod_end, 4.5, Color("f2d36e"))
			for vial_index: int in 3:
				var vial_at := -facing * 15.0 + right * (-12.0 + float(vial_index) * 12.0)
				draw_circle(vial_at, 4.0, [Color("dc6260"), Color("58c7a8"), Color("7a83c5")][vial_index])


func _draw_signature_preview(facing: Vector2, right: Vector2, accent: Color) -> void:
	var pulse := 0.72 + sin(_visual_time * 18.0) * 0.14
	match _active_action:
		&"mind_pierce":
			draw_line(facing * 28.0, facing * lerpf(92.0, 160.0, _signature_charge), Color(accent, pulse), lerpf(4.0, 9.0, _signature_charge), true)
		&"breach_bolt", &"power_arrow":
			var reach := lerpf(170.0, 390.0, _signature_charge)
			draw_line(facing * 40.0, facing * reach, Color(accent, 0.20 + _signature_charge * 0.42), 3.0, true)
			draw_line(facing * reach - right * 10.0, facing * reach + right * 10.0, Color("f0d56b"), 3.0, true)
		&"mutivarg_field":
			var center := facing * lerpf(190.0, 315.0, _signature_charge)
			var radius := lerpf(120.0, 205.0, _signature_charge)
			draw_circle(center, radius, Color(0.15, 0.72, 0.64, 0.045))
			draw_arc(center, radius, _visual_time, _visual_time + PI * 1.55, 72, Color(accent, 0.62), 3.0, true)


func _draw_form_wheel() -> void:
	var wheel_radius := 92.0
	draw_circle(Vector2.ZERO, wheel_radius + 24.0, Color(0.01, 0.02, 0.025, 0.82))
	for form_index: int in Form.size():
		var direction := [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT][form_index] as Vector2
		var selected := form_index == _form_preview
		var accent: Color = FORM_ACCENTS[form_index]
		var center := direction * wheel_radius
		draw_circle(center, 27.0 if selected else 21.0, Color(accent, 0.34 if selected else 0.12))
		draw_arc(center, 29.0 if selected else 23.0, 0.0, TAU, 24, Color(accent, 0.92 if selected else 0.46), 4.0 if selected else 2.0, true)
		draw_string(ThemeDB.fallback_font, center + Vector2(-8.0, 6.0), str(form_index + 1), HORIZONTAL_ALIGNMENT_CENTER, 16.0, 14, Color.WHITE)


func _draw_debug_attack() -> void:
	if not debug_draw_enabled or not _attack_area.monitoring or not _attack_shape.shape is RectangleShape2D:
		return
	var rectangle := _attack_shape.shape as RectangleShape2D
	var local_center := _attack_area.transform * _attack_shape.position
	var local_right := Vector2.RIGHT.rotated(_attack_area.rotation)
	var local_down := local_right.orthogonal()
	var half := rectangle.size * 0.5
	var points := PackedVector2Array([
		local_center - local_right * half.x - local_down * half.y,
		local_center + local_right * half.x - local_down * half.y,
		local_center + local_right * half.x + local_down * half.y,
		local_center - local_right * half.x + local_down * half.y,
	])
	draw_colored_polygon(points, Color(0.30, 0.86, 0.74, 0.10))
	draw_polyline(points + PackedVector2Array([points[0]]), Color(0.94, 0.77, 0.31, 0.78), 2.0, true)