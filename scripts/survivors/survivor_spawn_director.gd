class_name SurvivorSpawnDirector
extends RefCounted


const ROLE_COUNT := 6
const RANGED_ROLES := [3, 5]
const SUPPORT_ROLE := 4
const ROLE_THREAT := [1.0, 2.25, 1.20, 1.75, 2.10, 1.65]
const PHASES := [
	{
		&"name": &"DUEL",
		&"start_time": 0.0,
		&"base_cap": 1,
		&"hard_cap": 2,
		&"threat_cap": 2.20,
		&"ranged_cap": 0,
		&"support_cap": 0,
		&"spawn_interval": 2.80,
		&"minimum_interval": 1.60,
		&"performance_scale": 1.25,
		&"weights": [1.00, 0.00, 0.42, 0.00, 0.00, 0.00],
	},
	{
		&"name": &"SKIRMISH",
		&"start_time": 55.0,
		&"base_cap": 2,
		&"hard_cap": 3,
		&"threat_cap": 4.40,
		&"ranged_cap": 1,
		&"support_cap": 0,
		&"spawn_interval": 2.10,
		&"minimum_interval": 1.15,
		&"performance_scale": 1.55,
		&"weights": [1.00, 0.42, 0.72, 0.24, 0.00, 0.00],
	},
	{
		&"name": &"FORMATION",
		&"start_time": 130.0,
		&"base_cap": 3,
		&"hard_cap": 5,
		&"threat_cap": 7.60,
		&"ranged_cap": 1,
		&"support_cap": 0,
		&"spawn_interval": 1.55,
		&"minimum_interval": 0.82,
		&"performance_scale": 2.20,
		&"weights": [1.00, 0.62, 0.90, 0.46, 0.00, 0.18],
	},
	{
		&"name": &"PRESSURE",
		&"start_time": 240.0,
		&"base_cap": 5,
		&"hard_cap": 8,
		&"threat_cap": 12.50,
		&"ranged_cap": 2,
		&"support_cap": 1,
		&"spawn_interval": 1.10,
		&"minimum_interval": 0.58,
		&"performance_scale": 3.10,
		&"weights": [1.00, 0.72, 0.96, 0.64, 0.30, 0.48],
	},
	{
		&"name": &"ONSLAUGHT",
		&"start_time": 360.0,
		&"base_cap": 7,
		&"hard_cap": 12,
		&"threat_cap": 19.00,
		&"ranged_cap": 3,
		&"support_cap": 1,
		&"spawn_interval": 0.78,
		&"minimum_interval": 0.40,
		&"performance_scale": 4.20,
		&"weights": [0.92, 0.78, 1.00, 0.72, 0.38, 0.62],
	},
	{
		&"name": &"CLIMAX",
		&"start_time": 480.0,
		&"base_cap": 10,
		&"hard_cap": 18,
		&"threat_cap": 29.00,
		&"ranged_cap": 4,
		&"support_cap": 2,
		&"spawn_interval": 0.56,
		&"minimum_interval": 0.28,
		&"performance_scale": 6.20,
		&"weights": [0.86, 0.86, 1.00, 0.82, 0.48, 0.76],
	},
]

var _last_role := -1


func get_phase_index(run_time: float) -> int:
	var phase_index := 0
	for candidate_index: int in PHASES.size():
		if run_time < float(PHASES[candidate_index][&"start_time"]):
			break
		phase_index = candidate_index
	return phase_index


func get_phase_name(run_time: float) -> StringName:
	return PHASES[get_phase_index(run_time)][&"name"] as StringName


func get_target_count(run_time: float, kill_rate: float) -> int:
	var phase: Dictionary = PHASES[get_phase_index(run_time)]
	var performance_bonus := floori(maxf(0.0, kill_rate) * float(phase[&"performance_scale"]))
	return mini(int(phase[&"hard_cap"]), int(phase[&"base_cap"]) + performance_bonus)


func get_spawn_interval(run_time: float, kill_rate: float) -> float:
	var phase: Dictionary = PHASES[get_phase_index(run_time)]
	var accelerated_interval := float(phase[&"spawn_interval"]) / (1.0 + minf(1.5, maxf(0.0, kill_rate)) * 0.55)
	return maxf(float(phase[&"minimum_interval"]), accelerated_interval)


func get_hard_cap(run_time: float) -> int:
	return int(PHASES[get_phase_index(run_time)][&"hard_cap"])


func get_ranged_cap(run_time: float) -> int:
	return int(PHASES[get_phase_index(run_time)][&"ranged_cap"])


func can_spawn_role(run_time: float, active_roles: Array[int], role: int) -> bool:
	if role < 0 or role >= ROLE_COUNT:
		return false
	var phase: Dictionary = PHASES[get_phase_index(run_time)]
	var weights: Array = phase[&"weights"] as Array
	if float(weights[role]) <= 0.0:
		return false
	var role_count := active_roles.count(role)
	var same_role_cap := maxi(1, ceili(float(phase[&"hard_cap"]) * 0.45))
	if role_count >= same_role_cap:
		return false
	if role in RANGED_ROLES and _count_ranged(active_roles) >= int(phase[&"ranged_cap"]):
		return false
	if role == SUPPORT_ROLE and active_roles.count(SUPPORT_ROLE) >= int(phase[&"support_cap"]):
		return false
	var active_threat := 0.0
	for active_role: int in active_roles:
		if active_role >= 0 and active_role < ROLE_THREAT.size():
			active_threat += float(ROLE_THREAT[active_role])
	return active_threat + float(ROLE_THREAT[role]) <= float(phase[&"threat_cap"]) + 0.001


func choose_role(run_time: float, active_roles: Array[int], rng: RandomNumberGenerator) -> int:
	var phase: Dictionary = PHASES[get_phase_index(run_time)]
	var weights: Array = phase[&"weights"] as Array
	var candidates: Array[int] = []
	var candidate_weights: Array[float] = []
	var total_weight := 0.0
	for role: int in ROLE_COUNT:
		if not can_spawn_role(run_time, active_roles, role):
			continue
		var diversity_scale := 1.0 / (1.0 + float(active_roles.count(role)) * 0.85)
		var repeat_scale := 0.38 if role == _last_role else 1.0
		var adjusted_weight := float(weights[role]) * diversity_scale * repeat_scale
		candidates.append(role)
		candidate_weights.append(adjusted_weight)
		total_weight += adjusted_weight
	if candidates.is_empty() or total_weight <= 0.0:
		return -1
	var roll := rng.randf_range(0.0, total_weight)
	for candidate_index: int in candidates.size():
		roll -= candidate_weights[candidate_index]
		if roll <= 0.0:
			_last_role = candidates[candidate_index]
			return _last_role
	_last_role = candidates.back()
	return _last_role


func get_scaling(run_time: float) -> Dictionary:
	var elapsed_minutes := maxf(0.0, run_time) / 60.0
	return {
		&"health": 1.0 + elapsed_minutes * 0.12 + elapsed_minutes * elapsed_minutes * 0.015,
		&"resolve": 1.0 + elapsed_minutes * 0.10 + elapsed_minutes * elapsed_minutes * 0.012,
		&"damage": 1.0 + elapsed_minutes * 0.065 + elapsed_minutes * elapsed_minutes * 0.0085,
		&"speed": 1.0 + minf(0.16, elapsed_minutes * 0.016),
	}


func _count_ranged(active_roles: Array[int]) -> int:
	var count := 0
	for role: int in active_roles:
		if role in RANGED_ROLES:
			count += 1
	return count