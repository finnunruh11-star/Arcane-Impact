class_name MindLink
extends Node2D


var _end := Vector2.RIGHT * 100.0
var _power := 0.5
var _elapsed := 0.0
var _duration := 0.26
var _phase := 0.0


func configure(from: Vector2, to: Vector2, power: float) -> void:
	global_position = from
	_end = to - from
	_power = clampf(power, 0.1, 1.0)
	_duration = lerpf(0.18, 0.34, _power)
	_phase = from.x * 0.021 + from.y * 0.037 + to.x * 0.019


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 44
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
	var progress := clampf(_elapsed / _duration, 0.0, 1.0)
	var reveal := 1.0 - pow(1.0 - minf(progress * 2.6, 1.0), 3.0)
	var fade := pow(1.0 - progress, 1.25)
	var direction := _end / length
	var normal := direction.orthogonal()
	var segments := maxi(3, int(ceil(length / 46.0)))
	var points := PackedVector2Array()
	for index: int in segments + 1:
		var ratio := float(index) / float(segments)
		var wave := sin(_phase + ratio * TAU * 2.2 + floor(_elapsed * 34.0) * 0.42)
		var taper := sin(ratio * PI)
		points.append(_end * ratio * reveal + normal * wave * taper * lerpf(5.0, 16.0, _power))
	draw_polyline(points, Color(0.08, 0.44, 0.55, 0.30 * fade), lerpf(10.0, 18.0, _power), true)
	draw_polyline(points, Color(0.32, 0.91, 0.94, 0.76 * fade), lerpf(3.0, 5.5, _power), true)
	for point_index: int in points.size():
		if point_index % 2 == 0:
			draw_circle(points[point_index], lerpf(2.0, 4.5, _power), Color(0.91, 1.0, 0.59, fade))
