class_name SurvivorExperienceShard
extends Node2D


signal collected(value: int)

var _target: Node2D
var _value := 1
var _pickup_radius := 120.0
var _collected := false
var _pulse := 0.0


func configure(target: Node2D, value: int, pickup_radius: float) -> void:
	_target = target
	_value = maxi(1, value)
	_pickup_radius = maxf(32.0, pickup_radius)


func set_pickup_radius(pickup_radius: float) -> void:
	_pickup_radius = maxf(32.0, pickup_radius)


func _ready() -> void:
	z_index = 8
	queue_redraw()


func _process(delta: float) -> void:
	_pulse += delta
	if _collected or not is_instance_valid(_target):
		return
	var to_target := _target.global_position - global_position
	var distance := to_target.length()
	if distance <= 26.0:
		_collected = true
		collected.emit(_value)
		queue_free()
		return
	if distance <= _pickup_radius and distance > 0.001:
		var pull_ratio := 1.0 - distance / _pickup_radius
		var pull_speed := lerpf(250.0, 760.0, pull_ratio)
		global_position += to_target / distance * minf(distance, pull_speed * delta)
	queue_redraw()


func _draw() -> void:
	var glow := 0.62 + sin(_pulse * 5.5) * 0.16
	draw_circle(Vector2.ZERO, 12.0, Color(0.12, 0.82, 0.72, 0.12 * glow))
	var shard_points := PackedVector2Array([
		Vector2(0.0, -9.0),
		Vector2(7.0, 0.0),
		Vector2(0.0, 11.0),
		Vector2(-7.0, 0.0),
	])
	draw_colored_polygon(shard_points, Color(0.35, 0.96, 0.73, glow))
	draw_polyline(shard_points + PackedVector2Array([shard_points[0]]), Color("d9ffe4"), 1.5, true)