class_name SurvivorAbilityState
extends RefCounted


var _entries: Dictionary = {}
var _basic_attack_tier := 3
var _basic_attack_power := 1.0


func set_basic_attack_progress(tier: int, power: float) -> void:
	_basic_attack_tier = clampi(tier, 1, 5)
	_basic_attack_power = maxf(0.1, power)


func get_basic_attack_tier() -> int:
	return _basic_attack_tier


func get_basic_attack_power() -> float:
	return _basic_attack_power


func set_progress(slot: StringName, rank: int, tier: int, power: float, cooldown: float) -> void:
	_entries[slot] = {
		&"rank": maxi(0, rank),
		&"tier": clampi(tier, 1, 5),
		&"power": maxf(0.0, power),
		&"cooldown": maxf(0.01, cooldown),
	}


func is_unlocked(slot: StringName) -> bool:
	return get_rank(slot) > 0


func get_rank(slot: StringName) -> int:
	return int((_entries.get(slot, {}) as Dictionary).get(&"rank", 0))


func get_tier(slot: StringName) -> int:
	return int((_entries.get(slot, {}) as Dictionary).get(&"tier", 1))


func get_power(slot: StringName) -> float:
	return float((_entries.get(slot, {}) as Dictionary).get(&"power", 0.0))


func get_cooldown(slot: StringName) -> float:
	return float((_entries.get(slot, {}) as Dictionary).get(&"cooldown", 1.0))