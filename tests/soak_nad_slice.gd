extends SceneTree


const NadSliceScene := preload("res://scenes/arena/nad_combat_slice.tscn")


func _init() -> void:
	call_deferred(&"_run_soak")


func _run_soak() -> void:
	var scene := NadSliceScene.instantiate()
	root.add_child(scene)
	for _frame: int in 6:
		await process_frame

	var player: NadPlayer = scene.get_node(^"CombatWorld/Nad")
	player.set("_using_gamepad", true)
	var metrics := {&"hits": 0, &"incoming": 0, &"locks": 0}
	player.combat_impact.connect(func(_at: Vector2, _direction: Vector2, _packet: DamagePacket, _intensity: float) -> void:
		metrics[&"hits"] = int(metrics[&"hits"]) + 1
	)
	player.audio_requested.connect(func(cue: StringName, _power: float) -> void:
		if cue == &"nad_hurt":
			metrics[&"incoming"] = int(metrics[&"incoming"]) + 1
	)

	for frame_index: int in 900:
		var nearest := _nearest_enemy(player)
		if is_instance_valid(nearest):
			player.aim_direction = (nearest.global_position - player.global_position).normalized()
		if frame_index > 0 and frame_index % 54 == 0:
			player.mana = maxf(player.mana, NadPlayer.FORESEE_COST)
			player.call("_begin_foresee")
		match frame_index:
			120, 205, 290:
				player.mana = NadPlayer.MAX_MANA
				player.call("_cast_terrain_anchor")
			345:
				player.call("_cast_terrain_anchor")
			430:
				player.mana = NadPlayer.MAX_MANA
				Input.action_press(&"signature")
				player.call("_begin_eldritch_mantle")
				player.set("_mantle_charge", 0.88)
			456:
				Input.action_release(&"signature")
			560:
				player.mana = NadPlayer.MAX_MANA
				player.call("_begin_mental_cascade")
			650:
				for enemy_node: Node in get_nodes_in_group(&"enemies"):
					if enemy_node.has_method(&"apply_mental_focus") and enemy_node.has_method(&"is_alive") and bool(enemy_node.call(&"is_alive")):
						enemy_node.call(&"apply_mental_focus", 3, 8.0)
						enemy_node.call(&"apply_control_lock", 2.4)
						metrics[&"locks"] = int(metrics[&"locks"]) + 1
				player.mana = NadPlayer.MAX_MANA
				player.call("_begin_arcane_conduit")
			790:
				player.call("_begin_fold_space")
		await physics_frame
		await process_frame
		if player.health < 52.0 and player.is_alive():
			player.health = NadPlayer.MAX_HEALTH

	Input.action_release(&"signature")
	var failed := false
	if int(metrics[&"incoming"]) < 1:
		push_error("Nad soak did not observe a connected enemy attack.")
		failed = true
	if int(metrics[&"hits"]) < 5:
		push_error("Nad soak observed fewer than five player impacts.")
		failed = true
	if int(metrics[&"locks"]) < 1 or player.ultimate_cooldown <= 0.0:
		push_error("Nad soak did not complete a prepared Arcane Conduit.")
		failed = true

	print("SOAK %s: %d Nad impacts; %d enemy attacks connected; %d targets prepared." % [
		"FAIL" if failed else "PASS",
		int(metrics[&"hits"]),
		int(metrics[&"incoming"]),
		int(metrics[&"locks"]),
	])
	scene.queue_free()
	for _frame: int in 14:
		await process_frame
	quit(1 if failed else 0)


func _nearest_enemy(player: NadPlayer) -> Node2D:
	var nearest: Node2D
	var nearest_distance := INF
	for enemy_node: Node in get_nodes_in_group(&"enemies"):
		if not enemy_node is Node2D or not enemy_node.has_method(&"is_alive") or not bool(enemy_node.call(&"is_alive")):
			continue
		var enemy := enemy_node as Node2D
		var distance := player.global_position.distance_squared_to(enemy.global_position)
		if distance < nearest_distance:
			nearest = enemy
			nearest_distance = distance
	return nearest