class_name ArenaBackdrop
extends Node2D


const VIEW_SIZE := Vector2(1280.0, 720.0)
const PLAYABLE_RECT := Rect2(86.0, 78.0, 1108.0, 564.0)


func _ready() -> void:
	z_index = -20
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEW_SIZE), Color("091016"))
	draw_rect(Rect2(Vector2(0.0, 0.0), Vector2(1280.0, 58.0)), Color("11171c"))
	draw_rect(Rect2(Vector2(0.0, 662.0), Vector2(1280.0, 58.0)), Color("11171c"))

	var floor_color := Color("172128")
	draw_rect(PLAYABLE_RECT, floor_color)
	draw_rect(PLAYABLE_RECT.grow(-8.0), Color("121b21"), false, 2.0, true)

	for x: float in range(int(PLAYABLE_RECT.position.x) + 28, int(PLAYABLE_RECT.end.x), 56):
		draw_line(
			Vector2(x, PLAYABLE_RECT.position.y),
			Vector2(x, PLAYABLE_RECT.end.y),
			Color(0.20, 0.31, 0.34, 0.16),
			1.0
		)
	for y: float in range(int(PLAYABLE_RECT.position.y) + 28, int(PLAYABLE_RECT.end.y), 56):
		draw_line(
			Vector2(PLAYABLE_RECT.position.x, y),
			Vector2(PLAYABLE_RECT.end.x, y),
			Color(0.20, 0.31, 0.34, 0.16),
			1.0
		)

	_draw_corner_bracket(PLAYABLE_RECT.position + Vector2(18.0, 18.0), Vector2.ONE)
	_draw_corner_bracket(Vector2(PLAYABLE_RECT.end.x - 18.0, PLAYABLE_RECT.position.y + 18.0), Vector2(-1.0, 1.0))
	_draw_corner_bracket(Vector2(PLAYABLE_RECT.position.x + 18.0, PLAYABLE_RECT.end.y - 18.0), Vector2(1.0, -1.0))
	_draw_corner_bracket(PLAYABLE_RECT.end - Vector2(18.0, 18.0), -Vector2.ONE)

	var dais_center := Vector2(890.0, 360.0)
	for radius: float in [112.0, 84.0, 48.0]:
		draw_arc(dais_center, radius, 0.0, TAU, 72, Color(0.29, 0.54, 0.55, 0.22), 2.0, true)
	for index: int in 8:
		var angle := TAU * float(index) / 8.0
		var inner := dais_center + Vector2.from_angle(angle) * 52.0
		var outer := dais_center + Vector2.from_angle(angle) * 104.0
		draw_line(inner, outer, Color(0.34, 0.63, 0.61, 0.18), 3.0, true)


func _draw_corner_bracket(at: Vector2, direction: Vector2) -> void:
	var color := Color("b3c9c3")
	draw_line(at, at + Vector2(34.0 * direction.x, 0.0), color, 3.0, true)
	draw_line(at, at + Vector2(0.0, 34.0 * direction.y), color, 3.0, true)