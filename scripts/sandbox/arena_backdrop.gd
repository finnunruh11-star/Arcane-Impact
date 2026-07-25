class_name ArenaBackdrop
extends Node2D


const VIEW_SIZE := Vector2(1280.0, 720.0)
const PLAYABLE_RECT := Rect2(-640.0, -420.0, 2560.0, 1560.0)
const STRUCTURE_RECTS: Array[Rect2] = [
	Rect2(118.0, 112.0, 218.0, 78.0),
	Rect2(944.0, 118.0, 208.0, 82.0),
	Rect2(104.0, 516.0, 238.0, 84.0),
	Rect2(934.0, 508.0, 224.0, 88.0),
	Rect2(-258.0, 286.0, 198.0, 104.0),
	Rect2(1338.0, 292.0, 204.0, 102.0),
	Rect2(526.0, -188.0, 236.0, 92.0),
	Rect2(516.0, 816.0, 254.0, 96.0),
]


func _ready() -> void:
	z_index = -20
	_build_structure_collision()
	queue_redraw()


static func is_position_clear(point: Vector2, margin := 0.0) -> bool:
	for structure: Rect2 in STRUCTURE_RECTS:
		if structure.grow(margin).has_point(point):
			return false
	return PLAYABLE_RECT.grow(-margin).has_point(point)


func _build_structure_collision() -> void:
	for index: int in STRUCTURE_RECTS.size():
		var structure := STRUCTURE_RECTS[index]
		var body := StaticBody2D.new()
		body.name = "ReliquaryRuin%02d" % (index + 1)
		body.collision_layer = 4
		body.collision_mask = 0
		body.position = structure.get_center()
		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = structure.size
		collision.shape = shape
		body.add_child(collision)
		add_child(body)


func _draw() -> void:
	draw_rect(PLAYABLE_RECT.grow(180.0), Color("091016"))

	var floor_color := Color("172128")
	draw_rect(PLAYABLE_RECT, floor_color)
	draw_rect(PLAYABLE_RECT.grow(-12.0), Color("5a6c6b"), false, 4.0, true)

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

	var dais_center := Vector2(640.0, 360.0)
	for radius: float in [112.0, 84.0, 48.0]:
		draw_arc(dais_center, radius, 0.0, TAU, 72, Color(0.29, 0.54, 0.55, 0.22), 2.0, true)
	for index: int in 8:
		var angle := TAU * float(index) / 8.0
		var inner := dais_center + Vector2.from_angle(angle) * 52.0
		var outer := dais_center + Vector2.from_angle(angle) * 104.0
		draw_line(inner, outer, Color(0.34, 0.63, 0.61, 0.18), 3.0, true)

	for index: int in STRUCTURE_RECTS.size():
		_draw_structure(STRUCTURE_RECTS[index], index)


func _draw_structure(structure: Rect2, index: int) -> void:
	draw_rect(Rect2(structure.position + Vector2(9.0, 13.0), structure.size), Color(0.0, 0.0, 0.0, 0.34))
	draw_rect(structure, Color("273239"))
	draw_rect(structure.grow(-7.0), Color("111a20"), false, 3.0, true)
	var seam_color := Color(0.42, 0.57, 0.56, 0.24)
	for seam: float in range(int(structure.position.x) + 34, int(structure.end.x), 52):
		draw_line(Vector2(seam, structure.position.y + 8.0), Vector2(seam - 14.0, structure.end.y - 8.0), seam_color, 2.0, true)
	var rune_center := structure.get_center()
	var rune_color := Color("69b7a5") if index % 2 == 0 else Color("c49b55")
	draw_circle(rune_center, 13.0, Color(rune_color, 0.12))
	draw_arc(rune_center, 18.0, float(index) * 0.42, float(index) * 0.42 + PI * 1.55, 22, Color(rune_color, 0.62), 3.0, true)


func _draw_corner_bracket(at: Vector2, direction: Vector2) -> void:
	var color := Color("b3c9c3")
	draw_line(at, at + Vector2(34.0 * direction.x, 0.0), color, 3.0, true)
	draw_line(at, at + Vector2(0.0, 34.0 * direction.y), color, 3.0, true)