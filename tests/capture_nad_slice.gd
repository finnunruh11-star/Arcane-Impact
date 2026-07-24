extends SceneTree


const NadSliceScene := preload("res://scenes/arena/nad_combat_slice.tscn")


func _init() -> void:
	call_deferred(&"_capture")


func _capture() -> void:
	var scene := NadSliceScene.instantiate()
	root.add_child(scene)
	for _frame: int in 6:
		await process_frame

	var player: NadPlayer = scene.get_node(^"CombatWorld/Nad")
	var enemies: Array[Node] = get_nodes_in_group(&"enemies")
	player.global_position = Vector2(455.0, 360.0)
	player.aim_direction = Vector2.RIGHT
	player.set("_using_gamepad", true)
	var enemy_positions := [Vector2(720.0, 360.0), Vector2(650.0, 220.0), Vector2(650.0, 500.0)]
	for index: int in mini(enemies.size(), enemy_positions.size()):
		var enemy := enemies[index] as ReliquaryPursuer
		enemy.global_position = enemy_positions[index]
		enemy.process_mode = Node.PROCESS_MODE_DISABLED
		enemy.apply_mental_focus(index + 2, 8.0)
		enemy.apply_control_lock(5.0)
	(scene.get_node(^"NadCombatHud") as NadCombatHud).announce("MENTAL FOCUS")
	for _frame: int in 4:
		await process_frame
	if not _save_capture("nad_focus.png"):
		quit(1)
		return

	player.mana = NadPlayer.MAX_MANA
	for anchor_direction: Vector2 in [Vector2.RIGHT, Vector2(0.70, -0.70), Vector2(0.70, 0.70)]:
		player.aim_direction = anchor_direction.normalized()
		player.call("_cast_terrain_anchor")
	player.aim_direction = Vector2.RIGHT
	(scene.get_node(^"NadCombatHud") as NadCombatHud).announce("TERRAIN ANCHORS")
	for _frame: int in 6:
		await physics_frame
		await process_frame
	if not _save_capture("nad_anchors.png"):
		quit(1)
		return

	player.mana = NadPlayer.MAX_MANA
	Input.action_press(&"signature")
	player.call("_begin_eldritch_mantle")
	player.set("_mantle_charge", 0.84)
	(scene.get_node(^"NadCombatHud") as NadCombatHud).announce("ELDRITCH MANTLE")
	for _frame: int in 4:
		await physics_frame
		await process_frame
	if not _save_capture("nad_mantle.png"):
		quit(1)
		return
	Input.action_release(&"signature")
	for _frame: int in 10:
		await physics_frame
		await process_frame

	player.mana = NadPlayer.MAX_MANA
	player.call("_begin_arcane_conduit")
	for _frame: int in 24:
		await physics_frame
		await process_frame
	if not _save_capture("nad_conduit_charge.png"):
		quit(1)
		return
	for _frame: int in 18:
		await physics_frame
		await process_frame
	if not _save_capture("nad_conduit.png"):
		quit(1)
		return

	Input.action_release(&"signature")
	scene.queue_free()
	for _frame: int in 10:
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
