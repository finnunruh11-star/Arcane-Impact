class_name ThunderBurst
extends Node2D


var _radius := 160.0
var _power := 0.5
var _ultimate := false
var _elapsed := 0.0
var _duration := 0.48


func configure(at: Vector2, radius: float, power: float, ultimate: bool) -> void:
	global_position = at
	_radius = maxf(24.0, radius)
	_power = clampf(power, 0.0, 1.0)
	_ultimate = ultimate
	_duration = 0.68 if ultimate else 0.46


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 39
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
	var progress := clampf(_elapsed / _duration, 0.0, 1.0)
	var expansion := 1.0 - pow(1.0 - progress, 3.0)
	var fade := pow(1.0 - progress, 1.35)
	var wave_radius := _radius * expansion
	var inner_radius := wave_radius * (0.58 if _ultimate else 0.72)
	draw_circle(Vector2.ZERO, wave_radius, Color(0.08, 0.67, 1.0, fade * (0.11 if _ultimate else 0.08)))
	draw_arc(Vector2.ZERO, wave_radius, 0.0, TAU, 120, Color(0.23, 0.83, 1.0, fade * 0.72), lerpf(8.0, 15.0, _power), true)
	draw_arc(Vector2.ZERO, inner_radius, 0.0, TAU, 96, Color(1.0, 0.85, 0.20, fade * 0.92), lerpf(3.0, 8.0, _power), true)

	var ray_count := 16 if _ultimate else 9
	for ray_index: int in ray_count:
		var angle := TAU * float(ray_index) / float(ray_count) + sin(float(ray_index) * 4.73) * 0.11
		var direction := Vector2.from_angle(angle)
		var normal := direction.orthogonal()
		var ray_start := direction * wave_radius * 0.18
		var ray_end := direction * wave_radius
		var points := PackedVector2Array([
			ray_start,
			ray_start.lerp(ray_end, 0.36) + normal * sin(float(ray_index) * 7.1) * 11.0,
			ray_start.lerp(ray_end, 0.68) - normal * cos(float(ray_index) * 5.4) * 14.0,
			ray_end,
		])
		draw_polyline(points, Color(0.20, 0.76, 1.0, fade * 0.36), 7.0, true)
		draw_polyline(points, Color(1.0, 0.92, 0.43, fade * 0.88), 2.0, true)