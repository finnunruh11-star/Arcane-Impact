extends SceneTree


const FinSliceScene := preload("res://scenes/arena/fin_combat_slice.tscn")


func _init() -> void:
	call_deferred(&"_capture")


func _capture() -> void:
	var scene := FinSliceScene.instantiate()
	root.add_child(scene)
	for _frame: int in 6:
		await process_frame

	var player: FinPlayer = scene.get_node(^"CombatWorld/Fin")
	var hud: FinCombatHud = scene.get_node(^"FinCombatHud")
	var enemies: Array[Node] = get_nodes_in_group(&"enemies")
	player.global_position = Vector2(455.0, 360.0)
	player.aim_direction = Vector2.RIGHT
	player.set("_using_gamepad", true)
	var enemy_positions := [Vector2(720.0, 360.0), Vector2(690.0, 220.0), Vector2(690.0, 500.0)]
	for index: int in mini(enemies.size(), enemy_positions.size()):
		var enemy := enemies[index] as ReliquaryPursuer
		enemy.global_position = enemy_positions[index]
		enemy.process_mode = Node.PROCESS_MODE_DISABLED
		enemy.apply_pierce_mark(index + 2, 12.0)

	player.select_form(FinPlayer.Form.NIGHTBLADE)
	player.set("_state", FinPlayer.State.FREE)
	player.call("_cast_umbral_veil")
	hud.announce("NIGHTBLADE / UMBRAL VEIL")
	for _frame: int in 5:
		await process_frame
	if not _save_capture("fin_nightblade.png"):
		quit(1)
		return

	player.select_form(FinPlayer.Form.ARBALEST)
	player.set("_state", FinPlayer.State.FREE)
	player.set("_crossbow_loaded", true)
	Input.action_press(&"signature")
	player.call("_begin_signature")
	player.set("_signature_charge", 0.82)
	hud.announce("ARBALEST / BREACH BOLT")
	for _frame: int in 5:
		await process_frame
	if not _save_capture("fin_arbalest.png"):
		quit(1)
		return
	Input.action_release(&"signature")

	player.select_form(FinPlayer.Form.HUNTSMAN)
	player.set("_state", FinPlayer.State.FREE)
	player.aim_direction = Vector2(0.72, -0.69)
	player.call("_cast_shadow_bind")
	player.set("_state", FinPlayer.State.FREE)
	player.aim_direction = Vector2(0.72, 0.69)
	player.call("_cast_shadow_bind")
	player.aim_direction = Vector2.RIGHT
	hud.announce("HUNTSMAN / SHADOW BIND")
	for _frame: int in 5:
		await process_frame
	if not _save_capture("fin_huntsman.png"):
		quit(1)
		return

	player.select_form(FinPlayer.Form.ARTIFICER)
	player.set("_state", FinPlayer.State.FREE)
	player.set("_active_action", &"mutivarg_field")
	player.set("_signature_charge", 1.0)
	player.call("_release_signature")
	player.set("_state", FinPlayer.State.FREE)
	player.call("_throw_smoke_bomb")
	hud.announce("ARTIFICER / MUTIVARG'S ROD")
	for _frame: int in 8:
		await physics_frame
		await process_frame
	if not _save_capture("fin_artificer.png"):
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
