extends SceneTree


const FinSliceScene := preload("res://scenes/arena/fin_combat_slice.tscn")


func _init() -> void:
	call_deferred(&"_run_soak")


func _run_soak() -> void:
	var scene := FinSliceScene.instantiate()
	root.add_child(scene)
	for _frame: int in 6:
		await process_frame

	var player: FinPlayer = scene.get_node(^"CombatWorld/Fin")
	player.set("_using_gamepad", true)
	for enemy_node: Node in get_nodes_in_group(&"enemies"):
		if enemy_node is ReliquaryPursuer:
			var durable_enemy := enemy_node as ReliquaryPursuer
			durable_enemy.max_health = 3000.0
			durable_enemy.health = 3000.0
			durable_enemy.max_resolve = 900.0
			durable_enemy.resolve = 900.0
	var metrics := {&"hits": 0, &"incoming": 0, &"parries": 0, &"forms": {}}
	player.combat_impact.connect(func(_at: Vector2, _direction: Vector2, _packet: DamagePacket, _intensity: float) -> void:
		metrics[&"hits"] = int(metrics[&"hits"]) + 1
	)
	player.audio_requested.connect(func(cue: StringName, _power: float) -> void:
		if cue == &"fin_hurt":
			metrics[&"incoming"] = int(metrics[&"incoming"]) + 1
	)
	player.parry_impact.connect(func(_at: Vector2, _direction: Vector2, perfect: bool, _power: float) -> void:
		if perfect:
			metrics[&"parries"] = int(metrics[&"parries"]) + 1
	)

	for frame_index: int in 900:
		var nearest := _nearest_enemy(player)
		if is_instance_valid(nearest):
			player.aim_direction = (nearest.global_position - player.global_position).normalized()
		match frame_index:
			20:
				_visit_form(player, metrics, FinPlayer.Form.NIGHTBLADE)
				_place_target(nearest, player, 116.0)
				player.call("_begin_primary", 2)
				player.call("_resolve_primary")
			75:
				_reset_action_state(player)
				player.call("_cast_umbral_veil")
			100:
				_reset_action_state(player)
				player.call("_begin_shadow_lunge")
			180:
				_visit_form(player, metrics, FinPlayer.Form.ARBALEST)
				_place_target(nearest, player, 190.0)
				player.set("_crossbow_loaded", true)
				player.call("_begin_primary", 0)
				player.call("_resolve_primary")
			245:
				_reset_action_state(player)
				player.set("_crossbow_loaded", true)
				player.set("_active_action", &"breach_bolt")
				player.set("_signature_charge", 0.92)
				player.call("_release_signature")
			315:
				_visit_form(player, metrics, FinPlayer.Form.HUNTSMAN)
				_place_target(nearest, player, 235.0)
				player.call("_cast_shadow_bind")
			365:
				_reset_action_state(player)
				_place_target(nearest, player, 210.0)
				player.call("_begin_primary", 0)
				player.call("_resolve_primary")
			420:
				_reset_action_state(player)
				player.call("_throw_dagger")
			500:
				_visit_form(player, metrics, FinPlayer.Form.ARTIFICER)
				_place_target(nearest, player, 210.0)
				player.call("_begin_primary", 0)
				player.call("_resolve_primary")
			555:
				_reset_action_state(player)
				player.set("_active_action", &"mutivarg_field")
				player.set("_signature_charge", 0.88)
				player.call("_release_signature")
			620:
				_reset_action_state(player)
				player.use_potion(FinPlayer.Potion.VOLATILE)
			675:
				_reset_action_state(player)
				player.call("_throw_smoke_bomb")
			740:
				_reset_action_state(player)
				if is_instance_valid(nearest):
					_place_target(nearest, player, 112.0)
					nearest.set("_facing", -player.aim_direction)
					nearest.call("_begin_windup")
					player.call("_begin_masterful_parry")
					player.receive_hit(DamagePacket.enemy_melee(nearest, 32.0), -player.aim_direction)
			810:
				_reset_action_state(player)
				player.set("_invulnerable_time", 0.0)
				player.set("_veil_time", 0.0)
				player.set("_smoke_veil_time", 0.0)
				if is_instance_valid(nearest):
					player.receive_hit(DamagePacket.enemy_melee(nearest, 18.0), -player.aim_direction)
		await physics_frame
		await process_frame
		if player.health < 58.0 and player.is_alive():
			player.health = FinPlayer.MAX_HEALTH

	var failed := false
	if int(metrics[&"hits"]) < 5:
		push_error("Fin soak observed fewer than five player impacts.")
		failed = true
	if (metrics[&"forms"] as Dictionary).size() != FinPlayer.Form.size():
		push_error("Fin soak did not visit all four forms.")
		failed = true
	if int(metrics[&"parries"]) < 1:
		push_error("Fin soak did not resolve a perfect Masterful Parry.")
		failed = true
	if int(metrics[&"incoming"]) < 1:
		push_error("Fin soak did not observe incoming unguarded damage.")
		failed = true

	print("SOAK %s: %d Fin impacts; %d forms; %d perfect parries; %d enemy hits." % [
		"FAIL" if failed else "PASS",
		int(metrics[&"hits"]),
		(metrics[&"forms"] as Dictionary).size(),
		int(metrics[&"parries"]),
		int(metrics[&"incoming"]),
	])
	scene.queue_free()
	for _frame: int in 14:
		await process_frame
	quit(1 if failed else 0)


func _visit_form(player: FinPlayer, metrics: Dictionary, form: int) -> void:
	_reset_action_state(player)
	player.select_form(form)
	player.set("_state", FinPlayer.State.FREE)
	(metrics[&"forms"] as Dictionary)[form] = true


func _reset_action_state(player: FinPlayer) -> void:
	player.set("_state", FinPlayer.State.FREE)
	player.set("_state_time", 0.0)
	player.set("_invulnerable_time", 0.0)
	player.collision_mask = 2 | 4


func _place_target(target: Node2D, player: FinPlayer, distance: float) -> void:
	if not is_instance_valid(target):
		return
	target.global_position = player.global_position + player.aim_direction * distance
	if target.has_method(&"apply_control_lock"):
		target.call(&"apply_control_lock", 0.28)


func _nearest_enemy(player: FinPlayer) -> Node2D:
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