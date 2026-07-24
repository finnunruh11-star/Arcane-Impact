class_name PrototypePlayer
extends CharacterBody2D


signal cast_committed(charge: float)
signal impact_landed(at: Vector2, direction: Vector2, packet: DamagePacket, charge: float)
signal state_changed(label: String)
signal active_device_changed(using_gamepad: bool)

enum CastState {
	FREE,
	CHARGING,
	STARTUP,
	ACTIVE,
	RECOVERY,
}

const MOVE_SPEED := 330.0
const CHARGE_DURATION := 0.92
const STARTUP_DURATION := 0.15
const ACTIVE_DURATION := 0.09
const RECOVERY_DURATION := 0.34
const INPUT_BUFFER_DURATION := 0.12
const ATTACK_REACH := 188.0
const ATTACK_HALF_WIDTH := 54.0

var aim_direction := Vector2.RIGHT
var charge_ratio := 0.0
var debug_draw_enabled := false

var _state := CastState.FREE
var _state_time := 0.0
var _charge_elapsed := 0.0
var _using_gamepad := false
var _signature_buffer_remaining := 0.0
var _attack_area: Area2D
var _attack_shape: CollisionShape2D
var _hit_target_ids: Dictionary = {}


func _ready() -> void:
	InputProfile.ensure_default_bindings()
	collision_layer = 1
	collision_mask = 2 | 4
	z_index = 10

	var body_shape := CollisionShape2D.new()
	var body_circle := CircleShape2D.new()
	body_circle.radius = 29.0
	body_shape.shape = body_circle
	body_shape.position = Vector2(0.0, 4.0)
	add_child(body_shape)

	_attack_area = Area2D.new()
	_attack_area.name = "HeavyAttackArea"
	_attack_area.collision_layer = 8
	_attack_area.collision_mask = 16
	_attack_area.monitoring = false
	_attack_area.monitorable = false
	add_child(_attack_area)

	_attack_shape = CollisionShape2D.new()
	var attack_rectangle := RectangleShape2D.new()
	attack_rectangle.size = Vector2(ATTACK_REACH, ATTACK_HALF_WIDTH * 2.0)
	_attack_shape.shape = attack_rectangle
	_attack_shape.position = Vector2(ATTACK_REACH * 0.5, 0.0)
	_attack_area.add_child(_attack_shape)
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
	_update_aim()
	_update_input_buffer(delta)
	_update_cast(delta)
	_update_movement(delta)
	move_and_slide()
	_clamp_to_arena()
	queue_redraw()


func _update_input_buffer(delta: float) -> void:
	_signature_buffer_remaining = maxf(0.0, _signature_buffer_remaining - delta)
	if _state != CastState.FREE and Input.is_action_just_pressed(&"signature"):
		_signature_buffer_remaining = INPUT_BUFFER_DURATION


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


func _update_cast(delta: float) -> void:
	match _state:
		CastState.FREE:
			if Input.is_action_just_pressed(&"signature"):
				_begin_charge()
		CastState.CHARGING:
			_charge_elapsed = minf(_charge_elapsed + delta, CHARGE_DURATION)
			charge_ratio = CombatMath.normalized_charge(_charge_elapsed, CHARGE_DURATION)
			if not Input.is_action_pressed(&"signature"):
				_commit_cast()
		CastState.STARTUP:
			_state_time -= delta
			if _state_time <= 0.0:
				_begin_active()
		CastState.ACTIVE:
			_apply_attack_hits()
			_state_time -= delta
			if _state_time <= 0.0:
				_begin_recovery()
		CastState.RECOVERY:
			_state_time -= delta
			if _state_time <= 0.0:
				_set_state(CastState.FREE)
				if _signature_buffer_remaining > 0.0:
					_signature_buffer_remaining = 0.0
					_begin_charge()


func _update_movement(_delta: float) -> void:
	var move_input := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	var speed_scale := 1.0
	match _state:
		CastState.CHARGING:
			speed_scale = 0.52
		CastState.STARTUP:
			speed_scale = 0.28
		CastState.ACTIVE:
			speed_scale = 0.0
		CastState.RECOVERY:
			speed_scale = 0.64
	velocity = move_input * MOVE_SPEED * speed_scale


func _begin_charge() -> void:
	_charge_elapsed = 0.0
	charge_ratio = 0.0
	_set_state(CastState.CHARGING)


func _commit_cast() -> void:
	charge_ratio = CombatMath.normalized_charge(_charge_elapsed, CHARGE_DURATION)
	_state_time = STARTUP_DURATION
	_set_state(CastState.STARTUP)
	cast_committed.emit(charge_ratio)


func _begin_active() -> void:
	_state_time = ACTIVE_DURATION
	_hit_target_ids.clear()
	_attack_area.rotation = aim_direction.angle()
	_attack_area.monitoring = true
	_set_state(CastState.ACTIVE)


func _apply_attack_hits() -> void:
	for hurtbox: Area2D in _attack_area.get_overlapping_areas():
		var target := hurtbox.get_parent()
		if not is_instance_valid(target):
			continue
		var target_id := target.get_instance_id()
		if _hit_target_ids.has(target_id):
			continue
		_hit_target_ids[target_id] = true
		var packet := DamagePacket.heavy_slam(charge_ratio)
		if DamageResolver.apply(target, packet, aim_direction):
			var impact_position: Vector2 = target.global_position - aim_direction * 26.0
			impact_landed.emit(impact_position, aim_direction, packet, charge_ratio)


func _begin_recovery() -> void:
	_attack_area.monitoring = false
	_state_time = RECOVERY_DURATION
	_set_state(CastState.RECOVERY)


func _set_state(next_state: CastState) -> void:
	_state = next_state
	state_changed.emit(get_state_label())


func _set_using_gamepad(value: bool) -> void:
	if _using_gamepad == value:
		return
	_using_gamepad = value
	active_device_changed.emit(_using_gamepad)


func _clamp_to_arena() -> void:
	var bounds := ArenaBackdrop.PLAYABLE_RECT.grow(-34.0)
	global_position.x = clampf(global_position.x, bounds.position.x, bounds.end.x)
	global_position.y = clampf(global_position.y, bounds.position.y, bounds.end.y)


func is_using_gamepad() -> bool:
	return _using_gamepad


func get_state_label() -> String:
	return CastState.keys()[_state].capitalize()


func _draw() -> void:
	_draw_shadow()
	_draw_attack_preview()

	var facing := aim_direction
	var right := facing.orthogonal()
	var body_color := Color("dce8df")
	if _state == CastState.ACTIVE:
		body_color = Color("fff4cf")

	var cloak := PackedVector2Array([
		-facing * 25.0 + right * 24.0,
		-facing * 35.0,
		-facing * 25.0 - right * 24.0,
		facing * 16.0 - right * 19.0,
		facing * 27.0,
		facing * 16.0 + right * 19.0,
	])
	draw_colored_polygon(cloak, Color("29434a"))
	draw_circle(Vector2.ZERO, 23.0, body_color)
	draw_circle(-facing * 2.0, 15.0, Color("15252c"))
	draw_circle(facing * 5.0, 7.0, Color("50d9ce"))

	var shield_center := facing * 30.0 + right * 18.0
	draw_arc(shield_center, 23.0, aim_direction.angle() - 1.1, aim_direction.angle() + 1.1, 24, Color("f05b47"), 7.0, true)
	draw_line(facing * 30.0, facing * 69.0, Color(0.83, 0.95, 0.92, 0.78), 3.0, true)

	if _state == CastState.CHARGING:
		draw_arc(Vector2.ZERO, 43.0, -PI * 0.5, -PI * 0.5 + TAU * charge_ratio, 48, Color("ffd56a"), 5.0, true)


func _draw_shadow() -> void:
	draw_set_transform(Vector2(0.0, 23.0), 0.0, Vector2(1.35, 0.42))
	draw_circle(Vector2.ZERO, 27.0, Color(0.0, 0.0, 0.0, 0.34))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_attack_preview() -> void:
	if _state != CastState.CHARGING and _state != CastState.STARTUP and not debug_draw_enabled:
		return
	var facing := aim_direction
	var right := facing.orthogonal()
	var start := 8.0
	var width := ATTACK_HALF_WIDTH
	var corners := PackedVector2Array([
		facing * start + right * width,
		facing * ATTACK_REACH + right * width,
		facing * ATTACK_REACH - right * width,
		facing * start - right * width,
	])
	var fill_alpha := lerpf(0.06, 0.19, charge_ratio)
	draw_colored_polygon(corners, Color(0.95, 0.29, 0.20, fill_alpha))
	draw_polyline(corners + PackedVector2Array([corners[0]]), Color(1.0, 0.65, 0.36, 0.52), 2.0, true)