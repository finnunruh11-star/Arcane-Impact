extends SceneTree


const RosterScene := preload("res://scenes/roster_select.tscn")


func _init() -> void:
	call_deferred(&"_run")


func _run() -> void:
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
	print("NAVIGATION PASS: roster deploys Fin, Nad, Sniff, and Kat.")
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