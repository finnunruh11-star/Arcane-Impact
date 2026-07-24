class_name FinProjectile
extends Area2D


enum Kind {
	ARROW,
	POWER_ARROW,
	THROWING_DAGGER,
	CROSSBOW_BOLT,
	BREACH_BOLT,
	ROD_BOLT,
	FLASK,
}

var _owner: Node2D
var _kind := Kind.ARROW
var _direction := Vector2.RIGHT
var _charge := 0.0
var _origin := Vector2.ZERO
var _speed := 960.0
var _remaining := 0.90
var _pierces_remaining := 0
var _visual_time := 0.0
var _resolved_ids: Dictionary = {}


func configure(owner: Node2D, kind: Kind, direction: Vector2, charge := 0.0) -> void:
	_owner = owner
	_kind = kind
	_direction = direction.normalized() if not direction.is_zero_approx() else Vector2.RIGHT
	_charge = clampf(charge, 0.0, 1.0)
	rotation = _direction.angle()
	match _kind:
		Kind.ARROW:
			_speed = 980.0
			_remaining = 0.94
		Kind.POWER_ARROW:
			_speed = lerpf(1050.0, 1380.0, _charge)
			_remaining = 1.0
			_pierces_remaining = 1
		Kind.THROWING_DAGGER:
			_speed = 1120.0
			_remaining = 0.62
		Kind.CROSSBOW_BOLT:
			_speed = 1460.0
			_remaining = 0.78
		Kind.BREACH_BOLT:
			_speed = lerpf(1480.0, 1820.0, _charge)
			_remaining = 0.84
			_pierces_remaining = 3
		Kind.ROD_BOLT:
			_speed = 860.0
			_remaining = 0.88
		Kind.FLASK:
			_speed = 650.0
			_remaining = 0.44


func _ready() -> void:
	collision_layer = 8
	collision_mask = 16
	monitoring = true
	monitorable = false
	z_index = 18
	_origin = global_position
	var collision_shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 15.0 if _kind == Kind.BREACH_BOLT else (13.0 if _kind == Kind.FLASK else 9.0)
	collision_shape.shape = circle
	add_child(collision_shape)
	area_entered.connect(_on_area_entered)
	queue_redraw()


func _physics_process(delta: float) -> void:
	global_position += _direction * _speed * delta
	_remaining -= delta
	_visual_time += delta
	queue_redraw()
	if _remaining <= 0.0:
		if _kind == Kind.FLASK and is_instance_valid(_owner) and _owner.has_method(&"on_fin_projectile_expired"):
			_owner.call(&"on_fin_projectile_expired", _kind, global_position, _direction, _charge)
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	var target := area.get_parent() as Node2D
	if not is_instance_valid(target) or not target.is_in_group(&"enemies"):
		return
	var target_id := target.get_instance_id()
	if _resolved_ids.has(target_id):
		return
	_resolved_ids[target_id] = true
	if is_instance_valid(_owner) and _owner.has_method(&"on_fin_projectile_hit"):
		_owner.call(&"on_fin_projectile_hit", target, global_position, _direction, _kind, _charge, _origin.distance_to(global_position))
	if _kind == Kind.FLASK or _pierces_remaining <= 0:
		set_deferred(&"monitoring", false)
		queue_free()
	else:
		_pierces_remaining -= 1


func _draw() -> void:
	var pulse := 0.82 + sin(_visual_time * 38.0) * 0.18
	match _kind:
		Kind.ARROW, Kind.POWER_ARROW:
			var length := 42.0 if _kind == Kind.POWER_ARROW else 31.0
			draw_line(Vector2(-length, 0.0), Vector2(10.0, 0.0), Color("d9c98a"), 3.0, true)
			draw_colored_polygon(PackedVector2Array([Vector2(14.0, 0.0), Vector2(5.0, -5.0), Vector2(5.0, 5.0)]), Color("83d2ae"))
			if _kind == Kind.POWER_ARROW:
				draw_line(Vector2(-52.0, 0.0), Vector2(8.0, 0.0), Color(0.34, 0.88, 0.72, 0.25 * pulse), 10.0, true)
		Kind.THROWING_DAGGER:
			draw_colored_polygon(PackedVector2Array([Vector2(15.0, 0.0), Vector2(-8.0, -4.0), Vector2(-3.0, 0.0), Vector2(-8.0, 4.0)]), Color("d8e5dc"))
			draw_line(Vector2(-14.0, 0.0), Vector2(-5.0, 0.0), Color("8b5b42"), 4.0, true)
		Kind.CROSSBOW_BOLT, Kind.BREACH_BOLT:
			var bolt_length := 62.0 if _kind == Kind.BREACH_BOLT else 47.0
			draw_line(Vector2(-bolt_length, 0.0), Vector2(16.0, 0.0), Color("e7c65d"), 6.0 if _kind == Kind.BREACH_BOLT else 4.0, true)
			draw_colored_polygon(PackedVector2Array([Vector2(22.0, 0.0), Vector2(9.0, -8.0), Vector2(9.0, 8.0)]), Color("f5efe0"))
			draw_line(Vector2(-bolt_length - 18.0, 0.0), Vector2(-2.0, 0.0), Color(0.93, 0.42, 0.18, 0.30 * pulse), 13.0, true)
		Kind.ROD_BOLT:
			draw_circle(Vector2.ZERO, 12.0, Color(0.25, 0.91, 0.82, 0.18 * pulse))
			draw_circle(Vector2.ZERO, 5.0, Color("f0db74"))
			draw_line(Vector2(-31.0, 0.0), Vector2(-6.0, 0.0), Color(0.22, 0.75, 0.70, 0.56), 5.0, true)
		Kind.FLASK:
			draw_circle(Vector2.ZERO, 10.0, Color("6ed29f"))
			draw_rect(Rect2(Vector2(-3.0, -15.0), Vector2(6.0, 7.0)), Color("d8bf7b"))
