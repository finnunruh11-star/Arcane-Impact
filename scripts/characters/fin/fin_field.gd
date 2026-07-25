class_name FinField
extends Area2D


enum Kind {
	MUTIVARG,
	ALCHEMICAL_SMOKE,
}

var _owner: Node2D
var _kind := Kind.MUTIVARG
var _radius := 150.0
var _power := 0.5
var _ability_slot := StringName()
var _remaining := 3.0
var _pulse_timer := 0.10
var _visual_time := 0.0
var _entered_ids: Dictionary = {}


func configure(owner: Node2D, kind: Kind, radius: float, power := 0.5, ability_slot := StringName()) -> void:
	_owner = owner
	_kind = kind
	_ability_slot = ability_slot
	_radius = maxf(32.0, radius)
	_power = clampf(power, 0.0, 1.0)
	_remaining = lerpf(2.6, 3.8, _power) if _kind == Kind.MUTIVARG else 4.4


func _ready() -> void:
	collision_layer = 0
	collision_mask = 16
	monitoring = true
	monitorable = false
	z_index = 4
	var collision_shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = _radius
	collision_shape.shape = circle
	add_child(collision_shape)
	queue_redraw()


func _physics_process(delta: float) -> void:
	_remaining -= delta
	_pulse_timer -= delta
	_visual_time += delta
	var targets := _collect_targets()
	for target: Node2D in targets:
		if target.has_method(&"apply_temporary_slow"):
			target.call(&"apply_temporary_slow", lerpf(0.42, 0.24, _power) if _kind == Kind.MUTIVARG else 0.58, 0.26)
		var target_id := target.get_instance_id()
		if not _entered_ids.has(target_id):
			_entered_ids[target_id] = true
			if target.has_method(&"apply_pierce_mark"):
				target.call(&"apply_pierce_mark", 1, 8.0)
			if _kind == Kind.MUTIVARG and target.has_method(&"apply_control_lock"):
				target.call(&"apply_control_lock", lerpf(0.34, 0.72, _power))
	if _kind == Kind.ALCHEMICAL_SMOKE and is_instance_valid(_owner) and global_position.distance_to(_owner.global_position) <= _radius:
		if _owner.has_method(&"receive_smoke_veil"):
			_owner.call(&"receive_smoke_veil", 0.24)
	if _pulse_timer <= 0.0:
		_pulse_timer += 0.46 if _kind == Kind.MUTIVARG else 0.62
		_apply_pulse(targets)
	queue_redraw()
	if _remaining <= 0.0:
		queue_free()


func _collect_targets() -> Array[Node2D]:
	var targets: Array[Node2D] = []
	var seen: Dictionary = {}
	for hurtbox: Area2D in get_overlapping_areas():
		var target := hurtbox.get_parent() as Node2D
		if not is_instance_valid(target) or not target.is_in_group(&"enemies"):
			continue
		var target_id := target.get_instance_id()
		if seen.has(target_id):
			continue
		seen[target_id] = true
		targets.append(target)
	return targets


func _apply_pulse(targets: Array[Node2D]) -> void:
	for target: Node2D in targets:
		var direction := (target.global_position - global_position).normalized()
		var packet := DamagePacket.fin_mutivarg(_owner, _power) if _kind == Kind.MUTIVARG else DamagePacket.fin_alchemical(_owner)
		packet.survivor_ability_slot = _ability_slot
		var dealt := DamageResolver.apply_with_result(target, packet, direction)
		if dealt > 0.0 and is_instance_valid(_owner) and _owner.has_method(&"on_fin_field_hit"):
			_owner.call(&"on_fin_field_hit", target, global_position, direction, packet, _power, _kind)


func _draw() -> void:
	var fade := clampf(_remaining / 0.45, 0.0, 1.0)
	var pulse := 0.5 + 0.5 * sin(_visual_time * (7.5 if _kind == Kind.MUTIVARG else 3.8))
	if _kind == Kind.MUTIVARG:
		draw_circle(Vector2.ZERO, _radius, Color(0.08, 0.42, 0.39, (0.07 + pulse * 0.03) * fade))
		draw_arc(Vector2.ZERO, _radius, _visual_time * 0.42, _visual_time * 0.42 + PI * 1.64, 72, Color(0.28, 0.91, 0.78, 0.68 * fade), 4.0, true)
		draw_arc(Vector2.ZERO, _radius * (0.62 + pulse * 0.08), -_visual_time * 0.8, -_visual_time * 0.8 + PI * 1.30, 56, Color(0.95, 0.76, 0.30, 0.62 * fade), 3.0, true)
		for spoke_index: int in 8:
			var direction := Vector2.from_angle(TAU * float(spoke_index) / 8.0 + _visual_time * 0.18)
			draw_line(direction * _radius * 0.28, direction * _radius * (0.82 + pulse * 0.08), Color(0.30, 0.77, 0.69, 0.28 * fade), 2.0, true)
	else:
		draw_circle(Vector2.ZERO, _radius, Color(0.06, 0.09, 0.12, (0.30 + pulse * 0.08) * fade))
		draw_arc(Vector2.ZERO, _radius, -_visual_time * 0.28, -_visual_time * 0.28 + PI * 1.42, 64, Color(0.39, 0.82, 0.58, 0.48 * fade), 3.0, true)
		for mote_index: int in 12:
			var angle := float(mote_index) * 2.41 + _visual_time * (0.24 + float(mote_index % 3) * 0.08)
			var distance := _radius * (0.22 + 0.68 * fposmod(float(mote_index) * 0.37, 1.0))
			draw_circle(Vector2.from_angle(angle) * distance, 5.0 + pulse * 3.0, Color(0.42, 0.84, 0.58, 0.20 * fade))
