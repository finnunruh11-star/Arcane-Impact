class_name FloatingDamageLabel
extends Label


const LIFETIME := 0.72

var _elapsed := 0.0
var _drift := Vector2.ZERO


func configure(at: Vector2, amount: float, direction: Vector2) -> void:
	global_position = at - Vector2(42.0, 30.0)
	text = str(int(round(amount)))
	_drift = -direction.normalized() * 16.0 + Vector2(0.0, -58.0)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 60
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(84.0, 44.0)
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_theme_font_size_override(&"font_size", 28)
	add_theme_color_override(&"font_color", Color("fff2ce"))
	add_theme_color_override(&"font_shadow_color", Color(0.02, 0.03, 0.04, 0.92))
	add_theme_constant_override(&"shadow_offset_x", 2)
	add_theme_constant_override(&"shadow_offset_y", 3)


func _process(delta: float) -> void:
	_elapsed += delta
	global_position += _drift * delta
	_drift = _drift.lerp(Vector2(0.0, -26.0), delta * 5.0)
	var progress := clampf(_elapsed / LIFETIME, 0.0, 1.0)
	modulate.a = 1.0 - smoothstep(0.56, 1.0, progress)
	scale = Vector2.ONE * lerpf(1.28, 0.92, smoothstep(0.0, 0.34, progress))
	if _elapsed >= LIFETIME:
		queue_free()