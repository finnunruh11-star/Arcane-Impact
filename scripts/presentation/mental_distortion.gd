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
		&"conduit", &"cosmic_eye", &"abyssal_eye":
			_duration = 0.92
		&"anchor_detonate", &"void_anchor", &"tentacle_breach":
			_duration = 0.62
		&"void_prison", &"void_web", &"eldritch_web", &"rift":
			_duration = 0.72
		_:
			_duration = 0.48


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 40
	if not _is_void_kind():
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
	elif _is_void_kind():
		primary = Color(0.91, 0.16, 0.62, fade)
		secondary = Color(0.38, 0.78, 0.94, fade)

	if _is_void_kind():
		draw_circle(Vector2.ZERO, wave_radius, Color(0.012, 0.004, 0.027, fade * lerpf(0.32, 0.62, _power)))
	draw_circle(Vector2.ZERO, wave_radius, Color(primary, primary.a * lerpf(0.08, 0.14, _power)))
	draw_arc(Vector2.ZERO, wave_radius, 0.0, TAU, 112, Color(primary, primary.a * 0.78), lerpf(4.0, 11.0, _power), true)
	draw_arc(Vector2.ZERO, collapse_radius, -progress * 4.0, TAU - progress * 4.0, 96, Color(secondary, secondary.a * 0.72), lerpf(2.0, 6.0, _power), true)

	var spoke_count := 12 if _kind == &"conduit" or _kind == &"cosmic_eye" or _kind == &"abyssal_eye" else (9 if _is_void_kind() else 7)
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
	if _is_void_kind():
		var tendril_count := 5 + roundi(_power * 4.0)
		for tendril_index: int in tendril_count:
			var angle := _seed_phase + TAU * float(tendril_index) / float(tendril_count)
			var direction := Vector2.from_angle(angle)
			var normal := direction.orthogonal()
			var tendril_points := PackedVector2Array()
			for segment_index: int in 8:
				var ratio := float(segment_index) / 7.0
				var curl := sin(_seed_phase + progress * 10.0 + ratio * 8.0 + float(tendril_index)) * _radius * 0.11 * ratio
				tendril_points.append(direction * wave_radius * ratio + normal * curl)
			draw_polyline(tendril_points, Color(primary, fade * (0.32 + 0.26 * _power)), lerpf(2.0, 7.0, _power) * (1.0 - progress * 0.45), true)
	if _kind == &"cosmic_eye" or _kind == &"abyssal_eye" or _kind == &"void_anchor":
		var eye_size := maxf(18.0, collapse_radius * (0.32 if _kind != &"abyssal_eye" else 0.48))
		draw_set_transform(Vector2.ZERO, progress * 0.35, Vector2(1.0, 0.42))
		draw_circle(Vector2.ZERO, eye_size, Color(secondary, fade * 0.84))
		draw_circle(Vector2.ZERO, eye_size * 0.57, Color(0.01, 0.0, 0.025, fade * 0.96))
		draw_circle(Vector2(-eye_size * 0.16, -eye_size * 0.12), eye_size * 0.11, Color(primary, fade))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	var echo_count := 4 if _kind == &"conduit" else 2
	for echo_index: int in echo_count:
		var echo_ratio := fposmod(progress + float(echo_index) / float(echo_count), 1.0)
		var echo_radius := _radius * echo_ratio
		draw_arc(Vector2.ZERO, echo_radius, echo_ratio * PI, echo_ratio * PI + PI * 1.45, 54, Color(secondary, fade * (1.0 - echo_ratio) * 0.44), 2.0, true)


func _is_void_kind() -> bool:
	return _kind in [&"rift", &"void_prison", &"void_anchor", &"void_web", &"eldritch_web", &"tentacle_breach", &"cosmic_eye", &"abyssal_eye"]
