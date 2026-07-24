class_name CameraTrauma
extends Camera2D


@export_range(0.0, 3.0, 0.05) var trauma_decay := 1.65
@export_range(0.0, 40.0, 0.5) var maximum_offset := 22.0
@export_range(0.0, 0.1, 0.001) var maximum_rotation := 0.026

var trauma := 0.0
var intensity_scale := 1.0
var _phase := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	position = Vector2(640.0, 360.0)
	position_smoothing_enabled = false
	enabled = true


func add_trauma(amount: float) -> void:
	trauma = clampf(trauma + amount * intensity_scale, 0.0, 1.0)


func _process(delta: float) -> void:
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