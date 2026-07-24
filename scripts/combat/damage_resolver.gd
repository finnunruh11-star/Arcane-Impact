class_name DamageResolver
extends RefCounted


static func apply(target: Node, packet: DamagePacket, direction: Vector2) -> bool:
	if not is_instance_valid(target) or not target.has_method(&"receive_hit"):
		return false
	target.call(&"receive_hit", packet, direction.normalized())
	return true


static func apply_with_result(target: Node, packet: DamagePacket, direction: Vector2) -> float:
	if not is_instance_valid(target) or not target.has_method(&"receive_hit"):
		return 0.0
	var result: Variant = target.call(&"receive_hit", packet, direction.normalized())
	if result is float or result is int:
		return maxf(0.0, float(result))
	return packet.health_damage