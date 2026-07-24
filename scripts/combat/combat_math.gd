class_name CombatMath
extends RefCounted


static func normalized_charge(elapsed: float, duration: float) -> float:
	if duration <= 0.0:
		return 1.0
	return clampf(elapsed / duration, 0.0, 1.0)


static func shaped_charge(linear_charge: float) -> float:
	var clamped := clampf(linear_charge, 0.0, 1.0)
	return smoothstep(0.0, 1.0, clamped)


static func apply_radial_deadzone(value: Vector2, deadzone: float) -> Vector2:
	var magnitude := value.length()
	if magnitude <= deadzone:
		return Vector2.ZERO
	var scaled_magnitude := inverse_lerp(deadzone, 1.0, minf(magnitude, 1.0))
	return value.normalized() * scaled_magnitude


static func oriented_box_contains(
	origin: Vector2,
	direction: Vector2,
	point: Vector2,
	forward_distance: float,
	half_width: float
) -> bool:
	var facing := direction.normalized()
	if facing.is_zero_approx():
		return false
	var right := facing.orthogonal()
	var offset := point - origin
	var forward_projection := offset.dot(facing)
	var side_projection := absf(offset.dot(right))
	return forward_projection >= 0.0 \
		and forward_projection <= forward_distance \
		and side_projection <= half_width