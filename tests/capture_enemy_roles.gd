extends SceneTree


const KatSliceScene := preload("res://scenes/arena/kat_combat_slice.tscn")


func _init() -> void:
	call_deferred(&"_capture")


func _capture() -> void:
	var scene := KatSliceScene.instantiate() as SurvivorRun
	scene.audio_enabled = false
	root.add_child(scene)
	for _frame: int in 8:
		await process_frame

	for enemy_node: Node in get_nodes_in_group(&"enemies"):
		if scene.is_ancestor_of(enemy_node):
			enemy_node.process_mode = Node.PROCESS_MODE_DISABLED
			(enemy_node as CanvasItem).visible = false

	var player := scene.get_player() as Node2D
	player.process_mode = Node.PROCESS_MODE_DISABLED
	var world := scene.get_node(^"CombatWorld") as Node2D
	var offsets := [
		Vector2(-360.0, -55.0),
		Vector2(-120.0, -55.0),
		Vector2(130.0, -55.0),
		Vector2(360.0, -55.0),
		Vector2(-230.0, 180.0),
		Vector2(230.0, 180.0),
	]
	var roles: Array[ReliquaryPursuer] = []
	for role_index: int in ReliquaryPursuer.ROLE_COUNT:
		var enemy := ReliquaryPursuer.new()
		enemy.configure(player, role_index)
		world.add_child(enemy)
		enemy.global_position = player.global_position + offsets[role_index]
		enemy.set("_facing", (player.global_position - enemy.global_position).normalized())
		enemy.process_mode = Node.PROCESS_MODE_DISABLED
		enemy.queue_redraw()
		roles.append(enemy)
	await process_frame
	if not _save_capture("enemy_roles.png"):
		quit(1)
		return

	for enemy: ReliquaryPursuer in roles:
		enemy.call("_begin_windup")
		enemy.set("_state_time", enemy.windup_duration * 0.42)
		enemy.queue_redraw()
	roles[ReliquaryPursuer.Role.WARCALLER].set("_support_pulse_time", 0.36)
	roles[ReliquaryPursuer.Role.WARCALLER].queue_redraw()
	await process_frame
	if not _save_capture("enemy_attack_telegraphs.png"):
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