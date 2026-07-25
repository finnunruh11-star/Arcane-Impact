extends SceneTree


const KatSliceScene := preload("res://scenes/arena/kat_combat_slice.tscn")


func _init() -> void:
	call_deferred(&"_capture")


func _capture() -> void:
	var scene := KatSliceScene.instantiate()
	root.add_child(scene)
	for _frame: int in 6:
		await process_frame

	var player: KatPlayer = scene.get_node(^"CombatWorld/Kat")
	var enemies: Array[Node] = get_nodes_in_group(&"enemies")
	player.set_survivor_mode(false)
	player.global_position = Vector2(470.0, 360.0)
	player.aim_direction = Vector2.RIGHT
	player.set("_using_gamepad", true)
	var enemy_positions := [Vector2(640.0, 360.0), Vector2(760.0, 250.0), Vector2(770.0, 475.0)]
	for index: int in mini(enemies.size(), enemy_positions.size()):
		var enemy := enemies[index] as ReliquaryPursuer
		enemy.global_position = enemy_positions[index]
		enemy.process_mode = Node.PROCESS_MODE_DISABLED

	player.set_survivor_mode(true)
	player.set_survivor_basic_attack_progress(5, 2.15)
	player.set("_state", KatPlayer.State.FREE)
	player.aim_direction = Vector2.RIGHT
	player.call("_begin_primary", 2)
	player.call("_begin_primary_active")
	player.process_mode = Node.PROCESS_MODE_DISABLED
	(scene.get_node(^"KatCombatHud") as KatCombatHud).announce("BASIC ATTACK / TIER 5")
	for _frame: int in 12:
		await process_frame
	if not _save_capture("kat_primary_t5.png"):
		quit(1)
		return
	player.process_mode = Node.PROCESS_MODE_INHERIT
	(player.get("_attack_area") as Area2D).monitoring = false
	player.set("_state", KatPlayer.State.FREE)
	player.set_survivor_mode(false)
	for _frame: int in 18:
		await process_frame

	Input.action_press(&"signature")
	player.call("_begin_guard")
	for _frame: int in 10:
		await physics_frame
		await process_frame
	if not _save_capture("kat_guard.png"):
		quit(1)
		return

	player.set("_absorbed_force", 95.0)
	Input.action_release(&"signature")
	for _frame: int in 23:
		await physics_frame
		await process_frame
	if not _save_capture("kat_slam.png"):
		quit(1)
		return

	player.call("_cast_mourning_halo")
	for _frame: int in 9:
		await physics_frame
		await process_frame
	if not _save_capture("kat_halo.png"):
		quit(1)
		return

	for enemy_node: Node in enemies:
		if is_instance_valid(enemy_node) and enemy_node.has_method(&"apply_curse"):
			enemy_node.call(&"apply_curse", 3, 8.0)
	player.vitality = KatPlayer.MAX_VITALITY
	player.call("_begin_black_communion")
	for _frame: int in 64:
		await physics_frame
		await process_frame
	if not _save_capture("kat_communion.png"):
		quit(1)
		return

	Input.action_release(&"signature")
	scene.queue_free()
	for _frame: int in 4:
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