class_name LightningArc
extends Node2D


var _end := Vector2.RIGHT * 100.0
var _power := 0.5
var _elapsed := 0.0
var _duration := 0.16
var _phase := 0.0


func configure(from: Vector2, to: Vector2, power: float) -> void:
	global_position = from
	_end = to - from
	_power = clampf(power, 0.1, 1.0)
	_duration = lerpf(0.12, 0.21, _power)
	_phase = from.x * 0.017 + from.y * 0.031 + to.x * 0.013


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 45
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = additive
	queue_redraw()


func _process(delta: float) -> void:
	_elapsed += delta
	queue_redraw()
	if _elapsed >= _duration:
		queue_free()


func _draw() -> void:
	var length := _end.length()
	if length <= 1.0:
		return
	var fade := 1.0 - clampf(_elapsed / _duration, 0.0, 1.0)
	var direction := _end / length
	var normal := direction.orthogonal()
	var segments := maxi(4, int(ceil(length / 34.0)))
	var points := PackedVector2Array()
	for index: int in segments + 1:
		var ratio := float(index) / float(segments)
		var jitter := 0.0
		if index > 0 and index < segments:
			jitter = sin(_phase + float(index) * 12.71 + floor(_elapsed * 55.0) * 4.37) * lerpf(7.0, 17.0, _power)
		points.append(_end * ratio + normal * jitter)
	draw_polyline(points, Color(0.12, 0.68, 1.0, 0.20 * fade), lerpf(9.0, 16.0, _power), true)
	draw_polyline(points, Color(0.36, 0.87, 1.0, 0.78 * fade), lerpf(3.5, 6.0, _power), true)
	draw_polyline(points, Color(1.0, 0.95, 0.58, fade), lerpf(1.2, 2.4, _power), true)