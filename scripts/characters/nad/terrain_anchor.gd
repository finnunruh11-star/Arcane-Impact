class_name TerrainAnchor
extends Area2D


const RADIUS := 132.0
const DURATION := 12.0

var _owner: NadPlayer
var _remaining := DURATION
var _visual_time := 0.0
var _removed := false


func configure(owner: NadPlayer) -> void:
	_owner = owner


func _ready() -> void:
	collision_layer = 0
	collision_mask = 16
	monitoring = true
	monitorable = false
	z_index = 3
	var collision_shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = RADIUS
	collision_shape.shape = circle
	add_child(collision_shape)
	queue_redraw()


func _physics_process(delta: float) -> void:
	_remaining -= delta
	_visual_time += delta
	for hurtbox: Area2D in get_overlapping_areas():
		var target := hurtbox.get_parent() as Node2D
		if is_instance_valid(target) and target.is_in_group(&"enemies") and target.has_method(&"apply_temporary_slow"):
			target.call(&"apply_temporary_slow", 0.52, 0.26)
	if _remaining <= 0.0:
		_remove_anchor()
	queue_redraw()


func detonate() -> int:
	if _removed:
		return 0
	var hit_targets: Dictionary = {}
	var hit_count := 0
	for hurtbox: Area2D in get_overlapping_areas():
		var target := hurtbox.get_parent() as Node2D
		if not is_instance_valid(target) or not target.is_in_group(&"enemies"):
			continue
		var target_id := target.get_instance_id()
		if hit_targets.has(target_id):
			continue
		hit_targets[target_id] = true
		if target.has_method(&"apply_mental_focus"):
			target.call(&"apply_mental_focus", 1, 7.0)
		if target.has_method(&"apply_control_lock"):
			target.call(&"apply_control_lock", 0.65)
		var direction := (target.global_position - global_position).normalized()
		var packet := DamagePacket.nad_anchor(_owner)
		var dealt := DamageResolver.apply_with_result(target, packet, direction)
		if dealt > 0.0 and is_instance_valid(_owner):
			_owner.on_anchor_hit(target, global_position, direction, packet)
			hit_count += 1
	if is_instance_valid(_owner):
		_owner.on_anchor_detonated(global_position, hit_count)
	_remove_anchor()
	return hit_count


func get_remaining_ratio() -> float:
	return clampf(_remaining / DURATION, 0.0, 1.0)


func _remove_anchor() -> void:
	if _removed:
		return
	_removed = true
	monitoring = false
	if is_instance_valid(_owner):
		_owner.on_anchor_removed(self)
	queue_free()


func _draw() -> void:
	var life_ratio := get_remaining_ratio()
	var pulse := 0.5 + 0.5 * sin(_visual_time * 4.8)
	draw_circle(Vector2.ZERO, RADIUS, Color(0.08, 0.48, 0.58, 0.045 + pulse * 0.025))
	draw_arc(Vector2.ZERO, RADIUS, _visual_time * 0.42, _visual_time * 0.42 + PI * 1.55, 64, Color(0.26, 0.84, 0.91, 0.50 * life_ratio), 3.0, true)
	draw_arc(Vector2.ZERO, 86.0 + pulse * 8.0, -_visual_time * 0.68, -_visual_time * 0.68 + PI * 1.22, 48, Color(0.79, 0.86, 0.42, 0.42 * life_ratio), 2.0, true)
	for point_index: int in 6:
		var angle := _visual_time * -0.33 + TAU * float(point_index) / 6.0
		var point := Vector2.from_angle(angle) * 104.0
		draw_circle(point, 5.0, Color(0.45, 0.94, 1.0, (0.52 + pulse * 0.28) * life_ratio))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, -24.0), Vector2(15.0, 0.0), Vector2(0.0, 24.0), Vector2(-15.0, 0.0),
	]), Color(0.08, 0.18, 0.24, 0.94))
	draw_polyline(PackedVector2Array([
		Vector2(0.0, -24.0), Vector2(15.0, 0.0), Vector2(0.0, 24.0), Vector2(-15.0, 0.0), Vector2(0.0, -24.0),
	]), Color("8eefff"), 3.0, true)