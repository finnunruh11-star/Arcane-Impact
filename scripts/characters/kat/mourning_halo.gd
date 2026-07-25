class_name MourningHalo
extends Area2D


const RADIUS := 188.0
const DURATION := 5.2
const PULSE_INTERVAL := 0.58

var _owner: KatPlayer
var _tier := 3
var _radius := RADIUS
var _duration := DURATION
var _pulse_interval := PULSE_INTERVAL
var _remaining := DURATION
var _pulse_timer := 0.18
var _pulse_index := 0
var _visual_time := 0.0


func configure(owner: KatPlayer, tier := 3) -> void:
	_owner = owner
	_tier = clampi(tier, 1, 5)
	_radius = [126.0, 158.0, RADIUS, 226.0, 268.0][_tier - 1] as float
	_duration = [3.0, 4.1, DURATION, 6.2, 7.4][_tier - 1] as float
	_pulse_interval = [0.82, 0.68, PULSE_INTERVAL, 0.50, 0.40][_tier - 1] as float
	_remaining = _duration


func _ready() -> void:
	z_index = 4
	collision_layer = 0
	collision_mask = 16
	monitoring = true
	monitorable = false
	var collision_shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = _radius
	collision_shape.shape = circle
	add_child(collision_shape)
	queue_redraw()


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_owner) or not _owner.is_alive():
		queue_free()
		return
	_remaining -= delta
	_pulse_timer -= delta
	_visual_time += delta
	if _pulse_timer <= 0.0:
		_pulse_timer += _pulse_interval
		_pulse()
	if _remaining <= 0.0:
		queue_free()
	queue_redraw()


func _pulse() -> void:
	var hit_targets: Dictionary = {}
	var total_damage := 0.0
	var hit_count := 0
	for hurtbox: Area2D in get_overlapping_areas():
		var target := hurtbox.get_parent() as Node2D
		if not is_instance_valid(target) or not target.is_in_group(&"enemies"):
			continue
		var target_id := target.get_instance_id()
		if hit_targets.has(target_id):
			continue
		hit_targets[target_id] = true
		var direction := (target.global_position - global_position).normalized()
		var dealt := DamageResolver.apply_with_result(target, DamagePacket.kat_halo(_owner), direction)
		if target.has_method(&"apply_curse"):
			target.call(&"apply_curse", 2 if _tier >= 5 else 1, 4.5)
		if _tier >= 5 and target.has_method(&"pull_toward"):
			target.call(&"pull_toward", global_position, 115.0)
		total_damage += dealt
		hit_count += 1
		_owner.on_halo_target_hit(target, dealt, _pulse_index)
	_owner.on_halo_pulse(total_damage, hit_count)
	_pulse_index += 1


func _draw() -> void:
	var life_ratio := clampf(_remaining / _duration, 0.0, 1.0)
	var pulse := 0.5 + 0.5 * sin(_visual_time * TAU / _pulse_interval)
	draw_circle(Vector2.ZERO, _radius, Color(0.34, 0.02, 0.12, 0.055 + pulse * 0.035))
	for ring_index: int in 3:
		var radius := _radius - float(ring_index) * 18.0 + pulse * 5.0
		var start := _visual_time * (0.55 + float(ring_index) * 0.12) + float(ring_index) * 1.8
		draw_arc(
			Vector2.ZERO,
			radius,
			start,
			start + PI * (0.72 + 0.10 * float(ring_index)),
			36,
			Color(0.91, 0.19, 0.30, (0.38 - float(ring_index) * 0.08) * life_ratio),
			3.0,
			true
		)
	for rune_index: int in 8:
		var angle := _visual_time * -0.42 + TAU * float(rune_index) / 8.0
		var rune_position := Vector2.from_angle(angle) * (_radius - 30.0)
		draw_circle(rune_position, 3.0 + pulse * 2.0, Color(1.0, 0.58, 0.42, 0.45 * life_ratio))