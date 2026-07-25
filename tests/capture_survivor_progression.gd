extends SceneTree


const KatSliceScene := preload("res://scenes/arena/kat_combat_slice.tscn")


func _init() -> void:
	call_deferred(&"_capture")


func _capture() -> void:
	var run := KatSliceScene.instantiate() as SurvivorRun
	run.audio_enabled = false
	root.add_child(run)
	for _frame: int in 8:
		await process_frame

	for enemy_node: Node in get_nodes_in_group(&"enemies"):
		enemy_node.process_mode = Node.PROCESS_MODE_DISABLED
	var player := run.get_player()
	player.process_mode = Node.PROCESS_MODE_DISABLED
	if not _save_capture("survivor_arena_basic_only.png"):
		quit(1)
		return

	run.grant_test_experience(4)
	await process_frame
	if not _save_capture("survivor_six_choices.png"):
		quit(1)
		return

	run.choose_test_upgrade(&"signature")
	for _frame: int in 3:
		await process_frame
	if not _save_capture("survivor_first_unlock.png"):
		quit(1)
		return

	player.global_position = Vector2(1330.0, 360.0)
	player.process_mode = Node.PROCESS_MODE_INHERIT
	for _frame: int in 24:
		await process_frame
	player.process_mode = Node.PROCESS_MODE_DISABLED
	if not _save_capture("survivor_east_ruins.png"):
		quit(1)
		return

	run.queue_free()
	for _frame: int in 6:
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