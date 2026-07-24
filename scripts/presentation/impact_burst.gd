class_name ImpactBurst
extends Node2D


const DURATION := 0.38

var _elapsed := 0.0
var _direction := Vector2.RIGHT
var _power := 1.0


func configure(at: Vector2, direction: Vector2, power: float) -> void:
	global_position = at
	_direction = direction.normalized() if not direction.is_zero_approx() else Vector2.RIGHT
	_power = clampf(power, 0.0, 1.0)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 40


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= DURATION:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var progress := clampf(_elapsed / DURATION, 0.0, 1.0)
	var fade := 1.0 - progress
	var expansion := 1.0 - pow(1.0 - progress, 3.0)
	var radius := lerpf(14.0, 86.0 + 34.0 * _power, expansion)

	draw_circle(Vector2.ZERO, lerpf(24.0, 5.0, progress), Color(1.0, 0.98, 0.86, fade * 0.92))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 56, Color(0.98, 0.32, 0.21, fade * 0.72), 5.0, true)
	draw_arc(Vector2.ZERO, radius * 0.72, -1.1, 1.1, 24, Color(0.44, 0.93, 0.90, fade), 4.0, true)

	for index: int in 12:
		var spread := remap(float(index), 0.0, 11.0, -1.08, 1.08)
		var ray_direction := _direction.rotated(spread)
		var side := ray_direction.orthogonal()
		var length := (52.0 + float((index * 29) % 37)) * (0.8 + _power * 0.5) * expansion
		var width := lerpf(8.0, 1.0, progress)
		var shard := PackedVector2Array([
			ray_direction * 12.0 + side * width,
			ray_direction * length,
			ray_direction * 12.0 - side * width,
		])
		var color := Color(1.0, 0.48 + 0.28 * float(index % 2), 0.22, fade * 0.82)
		draw_colored_polygon(shard, color)