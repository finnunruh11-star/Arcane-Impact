extends SceneTree


const TrainingScene := preload("res://scenes/sandbox/training_run.tscn")
const TRAINING_HERO_SETTING := "arcane_impact/training_hero_index"


func _init() -> void:
	call_deferred(&"_capture")


func _capture() -> void:
	ProjectSettings.set_setting(TRAINING_HERO_SETTING, 1)
	var training := TrainingScene.instantiate()
	training.set(&"audio_enabled", false)
	root.add_child(training)
	for _frame: int in 8:
		await process_frame
	training.call(&"set_training_level", 20)
	for _frame: int in 6:
		await process_frame
	var destination := "user://training_mode.png"
	var error := root.get_texture().get_image().save_png(destination)
	if error != OK:
		push_error("Unable to save training capture: %s" % error_string(error))
		quit(1)
		return
	print("TRAINING CAPTURE: %s" % ProjectSettings.globalize_path(destination))
	training.queue_free()
	for _frame: int in 3:
		await process_frame
	quit(0)