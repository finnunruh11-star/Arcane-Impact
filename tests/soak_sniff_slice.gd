extends SceneTree


const SniffSliceScene := preload("res://scenes/arena/sniff_combat_slice.tscn")


func _init() -> void:
	call_deferred(&"_run_soak")


func _run_soak() -> void:
	var scene := SniffSliceScene.instantiate()
	root.add_child(scene)
	for _frame: int in 6:
		await process_frame

	var player: SniffPlayer = scene.get_node(^"CombatWorld/Sniff")
	var metrics := {&"hits": 0, &"incoming": 0}
	player.combat_impact.connect(func(_at: Vector2, _direction: Vector2, _packet: DamagePacket, _intensity: float) -> void:
		metrics[&"hits"] = int(metrics[&"hits"]) + 1
	)
	player.audio_requested.connect(func(cue: StringName, _power: float) -> void:
		if cue == &"sniff_hurt":
			metrics[&"incoming"] = int(metrics[&"incoming"]) + 1
	)

	for frame_index: int in 900:
		var nearest := _nearest_enemy(player)
		if is_instance_valid(nearest):
			player.aim_direction = (nearest.global_position - player.global_position).normalized()
		if frame_index > 0 and frame_index % 48 == 0:
			player.call("_spawn_dart")
		match frame_index:
			150:
				player.call("_cast_roaring_blessing")
			235:
				player.blessing = 7
				player.call("_begin_explosive_surge")
			360:
				player.blessing = 3
				player.call("_begin_thunder_dash")
				player.set("_dash_charge", 0.88)
				player.call("_release_thunder_dash")
			540:
				player.blessing = SniffPlayer.MAX_BLESSING
				player.call("_begin_divine_annihilation")
		await physics_frame
		await process_frame
		if player.health < 52.0 and player.is_alive():
			player.health = SniffPlayer.MAX_HEALTH

	var failed := false
	if int(metrics[&"incoming"]) < 1:
		push_error("Sniff soak did not observe a connected enemy attack.")
		failed = true
	if int(metrics[&"hits"]) < 4:
		push_error("Sniff soak observed fewer than four player impacts.")
		failed = true
	if player.ultimate_cooldown <= 0.0:
		push_error("Sniff soak did not complete Divine Annihilation.")
		failed = true

	print("SOAK %s: %d Sniff impacts; %d enemy attacks connected." % ["FAIL" if failed else "PASS", int(metrics[&"hits"]), int(metrics[&"incoming"])])
	scene.queue_free()
	for _frame: int in 14:
		await process_frame
	quit(1 if failed else 0)


func _nearest_enemy(player: SniffPlayer) -> Node2D:
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