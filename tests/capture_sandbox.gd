extends SceneTree


const SandboxScene := preload("res://scenes/sandbox/combat_sandbox.tscn")


func _init() -> void:
	call_deferred(&"_capture")


func _capture() -> void:
	var sandbox := SandboxScene.instantiate()
	root.add_child(sandbox)
	for _frame: int in 4:
		await process_frame

	var player: PrototypePlayer = sandbox.get_node(^"CombatWorld/PrototypePlayer")
	player.global_position = Vector2(680.0, 360.0)
	player.aim_direction = Vector2.RIGHT
	player.set("_using_gamepad", true)

	Input.action_press(&"signature")
	for _frame: int in 32:
		await physics_frame
	await process_frame

	var charge_destination := "user://combat_sandbox_charge.png"
	var error := root.get_texture().get_image().save_png(charge_destination)
	if error != OK:
		push_error("Unable to save charge capture: %s" % error_string(error))
		quit(1)
		return

	Input.action_release(&"signature")
	for _frame: int in 14:
		await physics_frame
	await process_frame

	var impact_destination := "user://combat_sandbox_impact.png"
	error = root.get_texture().get_image().save_png(impact_destination)
	if error != OK:
		push_error("Unable to save impact capture: %s" % error_string(error))
		quit(1)
		return
	print("CHARGE CAPTURE: %s" % ProjectSettings.globalize_path(charge_destination))
	print("IMPACT CAPTURE: %s" % ProjectSettings.globalize_path(impact_destination))
	sandbox.queue_free()
	for _frame: int in 3:
		await process_frame
	quit(0)