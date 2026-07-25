extends SceneTree


const RosterScene := preload("res://scenes/roster_select.tscn")


func _init() -> void:
	call_deferred(&"_run")


func _run() -> void:
	if not await _deploy_training_and_expect(1, "Sniff"):
		quit(1)
		return
	if not await _deploy_and_expect(3, "FinCombatSlice"):
		quit(1)
		return
	if not await _deploy_and_expect(2, "NadCombatSlice"):
		quit(1)
		return
	if not await _deploy_and_expect(1, "SniffCombatSlice"):
		quit(1)
		return
	if not await _deploy_and_expect(0, "KatCombatSlice"):
		quit(1)
		return
	print("NAVIGATION PASS: roster deploys all heroes and Sniff training.")
	if is_instance_valid(current_scene):
		current_scene.queue_free()
	for _frame: int in 8:
		await process_frame
	await create_timer(0.15, true, false, true).timeout
	quit(0)


func _deploy_and_expect(hero_index: int, expected_scene_name: String) -> bool:
	change_scene_to_packed(RosterScene)
	for _frame: int in 6:
		await process_frame
	var roster := current_scene
	if not is_instance_valid(roster):
		push_error("Roster scene did not instantiate.")
		return false
	roster.call("_deploy", hero_index)
	for _frame: int in 18:
		await physics_frame
		await process_frame
	if not is_instance_valid(current_scene) or current_scene.name != expected_scene_name:
		push_error("Roster expected %s but reached %s." % [expected_scene_name, current_scene.name if is_instance_valid(current_scene) else "nothing"])
		return false
	return true


func _deploy_training_and_expect(hero_index: int, expected_player_name: String) -> bool:
	change_scene_to_packed(RosterScene)
	for _frame: int in 6:
		await process_frame
	var roster := current_scene
	if not is_instance_valid(roster):
		push_error("Roster scene did not instantiate for training.")
		return false
	roster.call(&"_deploy_training", hero_index)
	for _frame: int in 18:
		await physics_frame
		await process_frame
	if not is_instance_valid(current_scene) or current_scene.name != "TrainingRun":
		push_error("Roster did not reach training mode.")
		return false
	var player := current_scene.call(&"get_player") as Node2D
	if not is_instance_valid(player) or player.name != expected_player_name:
		push_error("Training expected %s but created %s." % [expected_player_name, player.name if is_instance_valid(player) else "nothing"])
		return false
	return true