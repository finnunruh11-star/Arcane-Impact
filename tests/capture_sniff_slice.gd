extends SceneTree


const SniffSliceScene := preload("res://scenes/arena/sniff_combat_slice.tscn")


func _init() -> void:
	call_deferred(&"_capture")


func _capture() -> void:
	var scene := SniffSliceScene.instantiate()
	root.add_child(scene)
	for _frame: int in 6:
		await process_frame

	var player: SniffPlayer = scene.get_node(^"CombatWorld/Sniff")
	var enemies: Array[Node] = get_nodes_in_group(&"enemies")
	player.global_position = Vector2(455.0, 360.0)
	player.aim_direction = Vector2.RIGHT
	player.set("_using_gamepad", true)
	var enemy_positions := [Vector2(650.0, 360.0), Vector2(760.0, 255.0), Vector2(770.0, 475.0)]
	for index: int in mini(enemies.size(), enemy_positions.size()):
		var enemy := enemies[index] as ReliquaryPursuer
		enemy.global_position = enemy_positions[index]
		enemy.process_mode = Node.PROCESS_MODE_DISABLED

	player.set_survivor_mode(true)
	player.set_survivor_basic_attack_progress(5, 2.15)
	for slot: StringName in [&"signature", &"ability_1", &"ability_2", &"evade", &"ultimate"]:
		player.set_survivor_ability_progress(slot, 20, 5, 3.28, 0.72)
	var primary_target := enemies[0] as ReliquaryPursuer
	player.on_lightning_dart_hit(primary_target, primary_target.global_position, Vector2.RIGHT, player.blessing)
	(scene.get_node(^"SniffCombatHud") as SniffCombatHud).announce("BASIC ATTACK / TIER 5")
	for _frame: int in 2:
		await process_frame
	if not _save_capture("sniff_primary_t5.png"):
		quit(1)
		return
	player.set_survivor_mode(false)

	player.blessing = 6
	player.call("_cast_roaring_blessing")
	for _frame: int in 5:
		await physics_frame
		await process_frame
	if not _save_capture("sniff_crowned.png"):
		quit(1)
		return

	Input.action_press(&"signature")
	player.call("_begin_thunder_dash")
	player.set("_dash_charge", 0.82)
	(scene.get_node(^"SniffCombatHud") as SniffCombatHud).announce("THUNDER DASH")
	for _frame: int in 3:
		await physics_frame
		await process_frame
	if not _save_capture("sniff_dash_charge.png"):
		quit(1)
		return
	Input.action_release(&"signature")
	for _frame: int in 24:
		await physics_frame
		await process_frame

	player.global_position = Vector2(455.0, 360.0)
	player.blessing = SniffPlayer.MAX_BLESSING
	player.call("_begin_explosive_surge")
	(scene.get_node(^"SniffCombatHud") as SniffCombatHud).announce("EXPLOSIVE SURGE")
	for _frame: int in 19:
		await physics_frame
		await process_frame
	if not _save_capture("sniff_surge.png"):
		quit(1)
		return

	player.global_position = Vector2(455.0, 360.0)
	player.blessing = SniffPlayer.MAX_BLESSING
	player.call("_begin_divine_annihilation")
	for _frame: int in 45:
		await physics_frame
		await process_frame
	if not _save_capture("sniff_annihilation.png"):
		quit(1)
		return

	Input.action_release(&"signature")
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