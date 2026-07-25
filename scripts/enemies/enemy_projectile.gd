class_name EnemyProjectile
extends Area2D


signal attack_connected(at: Vector2, direction: Vector2, packet: DamagePacket, intensity: float)

enum Kind {
	ARCANE_ORB,
	DEADEYE_BOLT,
}

var _source: Node
var _target: Node2D
var _kind := Kind.ARCANE_ORB
var _direction := Vector2.RIGHT
var _speed := 280.0
var _damage := 20.0
var _radius := 15.0
var _lifetime := 4.0
var _homing_strength := 1.7
var _color := Color("69c7ff")


func configure(source: Node, target: Node2D, direction: Vector2, kind: int, damage: float) -> void:
	_source = source
	_target = target
	_kind = kind
	_direction = direction.normalized() if not direction.is_zero_approx() else Vector2.RIGHT
	_damage = damage
	match _kind:
		Kind.ARCANE_ORB:
			_speed = 270.0
			_radius = 17.0
			_lifetime = 4.2
			_homing_strength = 1.45
			_color = Color("69c7ff")
		Kind.DEADEYE_BOLT:
			_speed = 640.0
			_radius = 8.0
			_lifetime = 2.0
			_homing_strength = 0.0
			_color = Color("e4a6ff")


func _ready() -> void:
	collision_layer = 32
	collision_mask = 64 | 4
	monitoring = true
	monitorable = false
	z_index = 14
	rotation = _direction.angle()
	var collision_shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = _radius
	collision_shape.shape = circle
	add_child(collision_shape)
	queue_redraw()


func _physics_process(delta: float) -> void:
	_lifetime -= delta
	if _lifetime <= 0.0:
		queue_free()
		return
	if _homing_strength > 0.0 and is_instance_valid(_target):
		var target_direction := (_target.global_position - global_position).normalized()
		_direction = _direction.slerp(target_direction, clampf(_homing_strength * delta, 0.0, 1.0)).normalized()
		rotation = _direction.angle()
	global_position += _direction * _speed * delta
	for hurtbox: Area2D in get_overlapping_areas():
		if hurtbox.get_parent() != _target:
			continue
		var packet := DamagePacket.enemy_melee(_source, _damage)
		packet.knockback_force = 150.0 if _kind == Kind.ARCANE_ORB else 92.0
		packet.tags.append(&"projectile")
		var dealt := DamageResolver.apply_with_result(_target, packet, _direction)
		if dealt > 0.0:
			attack_connected.emit(global_position, _direction, packet, clampf(_damage / 30.0, 0.35, 1.0))
		queue_free()
		return
	if not get_overlapping_bodies().is_empty():
		queue_free()


func _draw() -> void:
	if _kind == Kind.ARCANE_ORB:
		draw_line(Vector2(-32.0, 0.0), Vector2(-8.0, 0.0), Color(_color, 0.35), 8.0, true)
		draw_circle(Vector2.ZERO, _radius + 5.0, Color(_color, 0.16))
		draw_circle(Vector2.ZERO, _radius, _color)
		draw_circle(Vector2(5.0, -4.0), 5.0, Color.WHITE)
	else:
		draw_line(Vector2(-38.0, 0.0), Vector2(3.0, 0.0), Color(_color, 0.70), 5.0, true)
		draw_colored_polygon(PackedVector2Array([
			Vector2(12.0, 0.0),
			Vector2(-2.0, -7.0),
			Vector2(-2.0, 7.0),
		]), _color)