extends SceneTree


const TrainingScene := preload("res://scenes/sandbox/training_run.tscn")
const TRAINING_HERO_SETTING := "arcane_impact/training_hero_index"

var _failures: Array[String] = []
var _checks := 0


func _init() -> void:
	call_deferred(&"_run")


func _run() -> void:
	for hero_index: int in 4:
		ProjectSettings.set_setting(TRAINING_HERO_SETTING, hero_index)
		var scene := TrainingScene.instantiate()
		scene.set(&"audio_enabled", false)
		root.add_child(scene)
		for _frame: int in 8:
			await process_frame
		var player := scene.call(&"get_player") as Node2D
		var dummies: Array = scene.call(&"get_dummies")
		_expect(is_instance_valid(player), "training creates hero %d" % hero_index)
		_expect(dummies.size() == 5, "training creates five dummies for hero %d" % hero_index)
		_expect(dummies.all(func(dummy: TargetDummy) -> bool: return dummy.is_in_group(&"enemies") and dummy.is_alive()), "all training dummies support enemy targeting")
		scene.call(&"set_training_level", 20)
		_expect(scene.call(&"get_training_level") == 20, "training level reaches 20")
		for slot: StringName in SurvivorProgression.ABILITY_SLOTS:
			_expect(bool(player.call(&"is_survivor_ability_unlocked", slot)), "level cheat unlocks %s for hero %d" % [slot, hero_index])
		var dummy := dummies[0] as TargetDummy
		dummy.health = 1.0
		dummy.apply_curse(2, 5.0)
		dummy.apply_mental_focus(2, 5.0)
		dummy.apply_control_lock(1.0)
		dummy.apply_pierce_mark(2, 5.0)
		scene.call(&"reset_dummies")
		_expect(dummy.health == dummy.max_health and not dummy.is_cursed() and dummy.get_mental_focus() == 0 and not dummy.is_control_locked() and dummy.consume_pierce_marks(12) == 0, "reset clears dummy combat state")
		scene.queue_free()
		for _frame: int in 8:
			await process_frame
	if _failures.is_empty():
		print("PASS: %d training mode checks." % _checks)
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)