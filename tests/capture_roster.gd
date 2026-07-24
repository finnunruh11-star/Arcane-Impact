extends SceneTree


const RosterScene := preload("res://scenes/roster_select.tscn")


func _init() -> void:
	call_deferred(&"_capture")


func _capture() -> void:
	var scene := RosterScene.instantiate()
	root.add_child(scene)
	for _frame: int in 8:
		await process_frame
	if not _save_capture("roster_kat.png"):
		quit(1)
		return

	scene.call("_select", 1)
	for _frame: int in 4:
		await process_frame
	if not _save_capture("roster_sniff.png"):
		quit(1)
		return

	scene.call("_select", 2)
	for _frame: int in 4:
		await process_frame
	if not _save_capture("roster_nad.png"):
		quit(1)
		return

	scene.call("_select", 3)
	for _frame: int in 4:
		await process_frame
	if not _save_capture("roster_fin.png"):
		quit(1)
		return

	scene.queue_free()
	for _frame: int in 8:
		await process_frame
	quit(0)


func _save_capture(file_name: String) -> bool:
	var destination := "user://%s" % file_name
	var error := root.get_texture().get_image().save_png(destination)
	if error != OK:
		push_error("Unable to save %s: %s" % [file_name, error_string(error)])
		return false
	print("CAPTURE: %s" % ProjectSettings.globalize_path(destination))
	return true