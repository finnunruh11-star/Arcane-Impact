class_name DamageResolver
extends RefCounted


static func apply(target: Node, packet: DamagePacket, direction: Vector2) -> bool:
	if not is_instance_valid(target) or not target.has_method(&"receive_hit"):
		return false
	_apply_survivor_power(packet)
	target.call(&"receive_hit", packet, direction.normalized())
	return true


static func apply_with_result(target: Node, packet: DamagePacket, direction: Vector2) -> float:
	if not is_instance_valid(target) or not target.has_method(&"receive_hit"):
		return 0.0
	_apply_survivor_power(packet)
	var result: Variant = target.call(&"receive_hit", packet, direction.normalized())
	if result is float or result is int:
		return maxf(0.0, float(result))
	return packet.health_damage


static func _apply_survivor_power(packet: DamagePacket) -> void:
	if packet.survivor_power_applied:
		return
	packet.survivor_power_applied = true
	if not is_instance_valid(packet.source) or not packet.source.has_method(&"get_survivor_power_multiplier"):
		return
	var multiplier := maxf(0.1, float(packet.source.call(&"get_survivor_power_multiplier")))
	packet.health_damage *= multiplier
	packet.resolve_damage *= multiplier