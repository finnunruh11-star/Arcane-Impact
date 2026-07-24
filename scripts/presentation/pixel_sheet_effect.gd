class_name PixelSheetEffect
extends Sprite2D


signal animation_finished

var _frame_count := 1
var _first_frame := 0
var _last_frame := 0
var _frames_per_second := 15.0
var _elapsed := 0.0
var _loop := false


func configure(
	sheet: Texture2D,
	frame_size: Vector2i,
	frames_per_second := 15.0,
	loop := false,
	first_frame := 0,
	last_frame := -1
) -> void:
	texture = sheet
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	centered = true
	hframes = maxi(1, int(sheet.get_width()) / frame_size.x)
	vframes = maxi(1, int(sheet.get_height()) / frame_size.y)
	_frame_count = hframes * vframes
	_first_frame = clampi(first_frame, 0, _frame_count - 1)
	_last_frame = _frame_count - 1 if last_frame < 0 else clampi(last_frame, _first_frame, _frame_count - 1)
	_frames_per_second = maxf(1.0, frames_per_second)
	_loop = loop
	frame = _first_frame
	_elapsed = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 42


func _process(delta: float) -> void:
	_elapsed += delta
	var frame_offset := int(floor(_elapsed * _frames_per_second))
	var animation_length := _last_frame - _first_frame + 1
	if _loop:
		frame = _first_frame + (frame_offset % animation_length)
		return
	if frame_offset >= animation_length:
		animation_finished.emit()
		queue_free()
		return
	frame = _first_frame + frame_offset


func finish() -> void:
	animation_finished.emit()
	queue_free()