class_name HitStop
extends Node


signal started(duration: float)
signal ended

var _remaining := 0.0
var _owns_pause := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func request(duration: float) -> void:
	if duration <= 0.0:
		return
	_remaining = maxf(_remaining, duration)
	if not get_tree().paused:
		get_tree().paused = true
		_owns_pause = true
		started.emit(_remaining)


func clear() -> void:
	_remaining = 0.0
	if _owns_pause and get_tree() != null:
		get_tree().paused = false
		_owns_pause = false
		ended.emit()


func _process(delta: float) -> void:
	if _remaining <= 0.0:
		return
	_remaining -= delta
	if _remaining <= 0.0:
		clear()


func _exit_tree() -> void:
	if _owns_pause and get_tree() != null:
		get_tree().paused = false