class_name SurvivorStatState
extends RefCounted


const STRENGTH := &"strength"
const DEXTERITY := &"dexterity"
const INTELLIGENCE := &"intelligence"
const MANA := &"mana"
const VITALITY := &"vitality"
const LUCK := &"luck"

var _ranks: Dictionary = {}


func add_rank(stat: StringName, amount := 1) -> void:
	_ranks[stat] = get_rank(stat) + maxi(0, amount)


func get_rank(stat: StringName) -> int:
	return int(_ranks.get(stat, 0))


func get_scaling_multiplier(scaling: StringName) -> float:
	match scaling:
		STRENGTH:
			return 1.0 + 0.12 * float(get_rank(STRENGTH))
		DEXTERITY:
			return 1.0 + 0.10 * float(get_rank(DEXTERITY))
		INTELLIGENCE:
			return 1.0 + 0.12 * float(get_rank(INTELLIGENCE))
		_:
			return 1.0


func get_health_multiplier() -> float:
	return 1.0 + 0.10 * float(get_rank(VITALITY))


func get_health_regen() -> float:
	return float(get_rank(VITALITY))


func get_resolve_multiplier() -> float:
	return 1.0 + 0.04 * float(get_rank(STRENGTH))


func get_move_speed_multiplier() -> float:
	return 1.0 + 0.03 * float(get_rank(DEXTERITY))


func get_mana_multiplier() -> float:
	return 1.0 + 0.15 * float(get_rank(MANA))


func get_mana_regen_multiplier() -> float:
	return 1.0 + 0.12 * float(get_rank(MANA))


func get_critical_chance() -> float:
	return minf(0.80, 0.04 * float(get_rank(LUCK)))


func get_critical_damage() -> float:
	return 1.50 + 0.10 * float(get_rank(LUCK))