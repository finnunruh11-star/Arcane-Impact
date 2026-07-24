class_name LeechMote
extends Node2D


enum MoteState {
	ORBIT,
	HUNT,
	RETURN,
}

const HUNT_RANGE := 460.0
const IMPACT_RANGE := 31.0
const HUNT_SPEED := 720.0

var _owner: KatPlayer
var _orbit_index := 0
var _orbit_phase := 0.0
var _attack_cooldown := 0.45
var _state := MoteState.ORBIT
var _target: Node2D
var _trail: Array[Vector2] = []


func configure(owner: KatPlayer, orbit_index: int) -> void:
	_owner = owner
	_orbit_index = orbit_index
	_orbit_phase = TAU * float(orbit_index) / 3.0


func _ready() -> void:
	z_index = 16
	queue_redraw()


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_owner) or not _owner.is_alive():
		queue_free()
		return

	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	_orbit_phase += delta * (1.7 + float(_orbit_index) * 0.12)
	match _state:
		MoteState.ORBIT:
			_move_to_orbit(delta, 9.0)
			if _attack_cooldown <= 0.0:
				_target = _choose_target()
				if is_instance_valid(_target):
					_state = MoteState.HUNT
		MoteState.HUNT:
			if not _target_is_valid():
				_state = MoteState.RETURN
			else:
				global_position = global_position.move_toward(_target.global_position, HUNT_SPEED * delta)
				if global_position.distance_to(_target.global_position) <= IMPACT_RANGE:
					_strike_target()
		MoteState.RETURN:
			_move_to_orbit(delta, 14.0)
			if global_position.distance_to(_orbit_position()) <= 18.0:
				_state = MoteState.ORBIT

	_trail.push_front(global_position)
	if _trail.size() > 9:
		_trail.pop_back()
	queue_redraw()


func _move_to_orbit(delta: float, responsiveness: float) -> void:
	global_position = global_position.lerp(_orbit_position(), 1.0 - exp(-responsiveness * delta))


func _orbit_position() -> Vector2:
	var radius := 70.0 + 8.0 * sin(_orbit_phase * 1.7)
	var offset := Vector2.from_angle(_orbit_phase) * radius
	offset.y *= 0.58
	return _owner.global_position + offset + Vector2(0.0, -12.0)


func _choose_target() -> Node2D:
	var best: Node2D
	var best_score := INF
	for candidate_node: Node in get_tree().get_nodes_in_group(&"enemies"):
		if not candidate_node is Node2D or not candidate_node.has_method(&"is_alive"):
			continue
		if not bool(candidate_node.call(&"is_alive")):
			continue
		var candidate := candidate_node as Node2D
		var distance := global_position.distance_to(candidate.global_position)
		if distance > HUNT_RANGE:
			continue
		var cursed_bonus := -180.0 if candidate.has_method(&"is_cursed") and bool(candidate.call(&"is_cursed")) else 0.0
		var score := distance + cursed_bonus
		if score < best_score:
			best_score = score
			best = candidate
	return best


func _target_is_valid() -> bool:
	return is_instance_valid(_target) \
		and _target.has_method(&"is_alive") \
		and bool(_target.call(&"is_alive"))


func _strike_target() -> void:
	var direction := (_target.global_position - global_position).normalized()
	var packet := DamagePacket.kat_mote(_owner)
	var dealt := DamageResolver.apply_with_result(_target, packet, direction)
	_owner.on_leech_hit(_target, dealt, direction)
	_attack_cooldown = 1.05 + 0.10 * float(_orbit_index)
	_state = MoteState.RETURN
	_target = null


func _draw() -> void:
	for index: int in range(_trail.size() - 1, 0, -1):
		var local_point := to_local(_trail[index])
		var alpha := (1.0 - float(index) / float(_trail.size())) * 0.34
		draw_circle(local_point, lerpf(2.0, 6.0, alpha), Color(0.86, 0.18, 0.32, alpha))
	draw_circle(Vector2.ZERO, 13.0, Color(0.12, 0.02, 0.09, 0.82))
	draw_arc(Vector2.ZERO, 14.0, 0.0, TAU, 20, Color("f14d6d"), 3.0, true)
	draw_circle(Vector2.ZERO, 6.0, Color("ffd0b7"))
	draw_circle(Vector2(-2.0, -2.0), 2.0, Color.WHITE)