class_name FinShadowTrap
extends Area2D


const RADIUS := 82.0
const DURATION := 8.0

var _owner: Node2D
var _tier := 3
var _radius := RADIUS
var _duration := DURATION
var _remaining := DURATION
var _visual_time := 0.0
var _triggered := false


func configure(owner: Node2D, tier := 3) -> void:
	_owner = owner
	_tier = clampi(tier, 1, 5)
	_radius = [58.0, 70.0, RADIUS, 98.0, 116.0][_tier - 1] as float
	_duration = [4.5, 6.0, DURATION, 10.5, 13.0][_tier - 1] as float
	_remaining = _duration


func _ready() -> void:
	collision_layer = 0
	collision_mask = 16
	monitoring = true
	monitorable = false
	z_index = 3
	var collision_shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = _radius
	collision_shape.shape = circle
	add_child(collision_shape)
	queue_redraw()


func _physics_process(delta: float) -> void:
	_remaining -= delta
	_visual_time += delta
	if not _triggered:
		for hurtbox: Area2D in get_overlapping_areas():
			var target := hurtbox.get_parent() as Node2D
			if is_instance_valid(target) and target.is_in_group(&"enemies"):
				_trigger(target)
				break
	queue_redraw()
	if _remaining <= 0.0:
		_remove_trap()


func _trigger(target: Node2D) -> void:
	_triggered = true
	monitoring = false
	if target.has_method(&"apply_pierce_mark"):
		target.call(&"apply_pierce_mark", [1, 1, 2, 3, 4][_tier - 1] as int, 9.0)
	if target.has_method(&"apply_control_lock"):
		target.call(&"apply_control_lock", [0.62, 0.92, 1.35, 1.85, 2.50][_tier - 1] as float)
	if is_instance_valid(_owner) and _owner.has_method(&"on_shadow_trap_triggered"):
		_owner.call(&"on_shadow_trap_triggered", self, target, global_position)
	queue_free()


func _remove_trap() -> void:
	if is_instance_valid(_owner) and _owner.has_method(&"on_shadow_trap_removed"):
		_owner.call(&"on_shadow_trap_removed", self)
	queue_free()


func _draw() -> void:
	var life_ratio := clampf(_remaining / _duration, 0.0, 1.0)
	var pulse := 0.5 + 0.5 * sin(_visual_time * 5.2)
	draw_circle(Vector2.ZERO, _radius, Color(0.12, 0.04, 0.20, 0.12 * life_ratio))
	draw_arc(Vector2.ZERO, _radius, _visual_time * 0.36, _visual_time * 0.36 + PI * 1.52, 54, Color(0.51, 0.33, 0.76, 0.62 * life_ratio), 3.0, true)
	for point_index: int in 4:
		var direction := Vector2.from_angle(PI * 0.25 + TAU * float(point_index) / 4.0)
		var outer := direction * (_radius - 9.0)
		draw_line(direction * 24.0, outer, Color(0.34, 0.83, 0.86, (0.35 + pulse * 0.24) * life_ratio), 3.0, true)
		draw_circle(outer, 5.0, Color("e6c45b"))