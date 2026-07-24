class_name MentalDistortion
extends Node2D


var _radius := 120.0
var _power := 0.5
var _kind: StringName = &"mantle"
var _elapsed := 0.0
var _duration := 0.52
var _seed_phase := 0.0


func configure(at: Vector2, radius: float, power: float, kind: StringName) -> void:
	global_position = at
	_radius = maxf(24.0, radius)
	_power = clampf(power, 0.1, 1.0)
	_kind = kind
	_seed_phase = at.x * 0.0127 + at.y * 0.0193
	match _kind:
		&"fold", &"phase":
			_duration = 0.30
		&"conduit":
			_duration = 0.92
		&"anchor_detonate":
			_duration = 0.62
		_:
			_duration = 0.48


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 40
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
	var collapse_radius := _radius * (1.0 - expansion * 0.76)
	var primary := Color(0.26, 0.91, 0.94, fade)
	var secondary := Color(0.88, 1.0, 0.54, fade)
	if _kind == &"phase" or _kind == &"fold":
		primary = Color(0.50, 0.93, 1.0, fade)
		secondary = Color(0.77, 0.65, 1.0, fade)
	elif _kind == &"conduit":
		primary = Color(0.32, 1.0, 0.88, fade)
		secondary = Color(0.98, 1.0, 0.62, fade)

	draw_circle(Vector2.ZERO, wave_radius, Color(primary, primary.a * lerpf(0.08, 0.14, _power)))
	draw_arc(Vector2.ZERO, wave_radius, 0.0, TAU, 112, Color(primary, primary.a * 0.78), lerpf(4.0, 11.0, _power), true)
	draw_arc(Vector2.ZERO, collapse_radius, -progress * 4.0, TAU - progress * 4.0, 96, Color(secondary, secondary.a * 0.72), lerpf(2.0, 6.0, _power), true)

	var spoke_count := 10 if _kind == &"conduit" else 7
	for spoke_index: int in spoke_count:
		var angle := _seed_phase + TAU * float(spoke_index) / float(spoke_count) + progress * (1.8 if spoke_index % 2 == 0 else -1.2)
		var direction := Vector2.from_angle(angle)
		var normal := direction.orthogonal()
		var start := direction * collapse_radius * 0.32
		var end := direction * wave_radius
		var bend := sin(float(spoke_index) * 9.17 + progress * 13.0) * _radius * 0.08
		var points := PackedVector2Array([
			start,
			start.lerp(end, 0.48) + normal * bend,
			end,
		])
		draw_polyline(points, Color(primary, primary.a * 0.42), lerpf(2.0, 5.0, _power), true)

	var echo_count := 4 if _kind == &"conduit" else 2
	for echo_index: int in echo_count:
		var echo_ratio := fposmod(progress + float(echo_index) / float(echo_count), 1.0)
		var echo_radius := _radius * echo_ratio
		draw_arc(Vector2.ZERO, echo_radius, echo_ratio * PI, echo_ratio * PI + PI * 1.45, 54, Color(secondary, fade * (1.0 - echo_ratio) * 0.44), 2.0, true)
