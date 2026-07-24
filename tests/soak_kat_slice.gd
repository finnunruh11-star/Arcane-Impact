extends SceneTree


const KatSliceScene := preload("res://scenes/arena/kat_combat_slice.tscn")


func _init() -> void:
	call_deferred(&"_run_soak")


func _run_soak() -> void:
	var scene := KatSliceScene.instantiate()
	root.add_child(scene)
	for _frame: int in 5:
		await process_frame

	var player: KatPlayer = scene.get_node(^"CombatWorld/Kat")
	player.health = 100000.0
	var starting_health := player.health
	for _frame: int in 900:
		await physics_frame
		await process_frame

	if player.health >= starting_health:
		push_error("Kat soak did not observe a connected enemy attack.")
		scene.queue_free()
		await process_frame
		quit(1)
		return

	print("SOAK PASS: enemy attacks connected; Kat lost %.1f health." % (starting_health - player.health))
	scene.queue_free()
	for _frame: int in 12:
		await process_frame
	quit(0)