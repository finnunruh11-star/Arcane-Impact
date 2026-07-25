class_name CameraTrauma
extends Camera2D


@export_range(0.0, 3.0, 0.05) var trauma_decay := 1.65
@export_range(0.0, 40.0, 0.5) var maximum_offset := 22.0
@export_range(0.0, 0.1, 0.001) var maximum_rotation := 0.026

var trauma := 0.0
var intensity_scale := 1.0
var _phase := 0.0
var _follow_target: Node2D
var _follow_bounds := Rect2()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	position = Vector2(640.0, 360.0)
	position_smoothing_enabled = false
	enabled = true


func configure_follow(target: Node2D, bounds: Rect2) -> void:
	_follow_target = target
	_follow_bounds = bounds.abs()
	position = get_clamped_follow_position(target.global_position)


func get_clamped_follow_position(target_position: Vector2) -> Vector2:
	if not _follow_bounds.has_area():
		return target_position
	var half_view := get_viewport_rect().size * 0.5
	if half_view.is_zero_approx():
		half_view = Vector2(640.0, 360.0)
	var minimum := _follow_bounds.position + half_view
	var maximum := _follow_bounds.end - half_view
	return Vector2(
		(_follow_bounds.get_center().x if minimum.x > maximum.x else clampf(target_position.x, minimum.x, maximum.x)),
		(_follow_bounds.get_center().y if minimum.y > maximum.y else clampf(target_position.y, minimum.y, maximum.y))
	)


func add_trauma(amount: float) -> void:
	trauma = clampf(trauma + amount * intensity_scale, 0.0, 1.0)


func _process(delta: float) -> void:
	if is_instance_valid(_follow_target):
		var target_position := get_clamped_follow_position(_follow_target.global_position)
		position = position.lerp(target_position, 1.0 - exp(-8.0 * delta))
	trauma = maxf(0.0, trauma - trauma_decay * delta)
	if trauma <= 0.0001:
		offset = Vector2.ZERO
		rotation = 0.0
		return

	_phase += delta * 46.0
	var strength := trauma * trauma
	offset = Vector2(
		sin(_phase * 1.07) + sin(_phase * 2.31) * 0.35,
		cos(_phase * 1.37) + sin(_phase * 2.73) * 0.35
	) * maximum_offset * strength
	rotation = sin(_phase * 1.79) * maximum_rotation * strength