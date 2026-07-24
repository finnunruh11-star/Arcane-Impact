class_name TargetDummy
extends CharacterBody2D


signal stats_changed
signal impact_received(amount: float, at: Vector2)
signal defeated

const MAX_HEALTH := 260.0
const MAX_RESOLVE := 150.0
const RESET_DELAY := 0.95

var health := MAX_HEALTH
var resolve := MAX_RESOLVE
var is_resolve_broken := false

var _spawn_position := Vector2.ZERO
var _knockback_velocity := Vector2.ZERO
var _hit_flash := 0.0
var _break_timer := 0.0
var _reset_timer := 0.0


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1 | 4
	z_index = 9
	_spawn_position = global_position

	var body_shape := CollisionShape2D.new()
	var body_circle := CircleShape2D.new()
	body_circle.radius = 38.0
	body_shape.shape = body_circle
	body_shape.position = Vector2(0.0, 5.0)
	add_child(body_shape)

	var hurtbox := Area2D.new()
	hurtbox.name = "Hurtbox"
	hurtbox.collision_layer = 16
	hurtbox.collision_mask = 0
	hurtbox.monitorable = true
	hurtbox.monitoring = false
	add_child(hurtbox)
	var hurt_shape := CollisionShape2D.new()
	var hurt_circle := CircleShape2D.new()
	hurt_circle.radius = 43.0
	hurt_shape.shape = hurt_circle
	hurt_shape.position = Vector2(0.0, 5.0)
	hurtbox.add_child(hurt_shape)
	queue_redraw()


func receive_hit(packet: DamagePacket, direction: Vector2) -> void:
	if _reset_timer > 0.0:
		return
	health = maxf(0.0, health - packet.health_damage)
	if not is_resolve_broken:
		resolve = maxf(0.0, resolve - packet.resolve_damage)
		if resolve <= 0.0:
			is_resolve_broken = true
			_break_timer = 1.35
	_knockback_velocity += direction.normalized() * packet.knockback_force
	_hit_flash = 1.0
	impact_received.emit(packet.health_damage, global_position - direction * 20.0)
	stats_changed.emit()
	if health <= 0.0:
		_reset_timer = RESET_DELAY
		defeated.emit()
	queue_redraw()


func reset_full() -> void:
	health = MAX_HEALTH
	resolve = MAX_RESOLVE
	is_resolve_broken = false
	_break_timer = 0.0
	_reset_timer = 0.0
	_knockback_velocity = Vector2.ZERO
	global_position = _spawn_position
	scale = Vector2.ONE
	stats_changed.emit()
	queue_redraw()


func _physics_process(delta: float) -> void:
	_hit_flash = maxf(0.0, _hit_flash - delta * 7.5)
	if _reset_timer > 0.0:
		_reset_timer -= delta
		scale = Vector2.ONE * clampf(_reset_timer / RESET_DELAY, 0.18, 1.0)
		if _reset_timer <= 0.0:
			reset_full()
		queue_redraw()
		return

	if is_resolve_broken:
		_break_timer -= delta
		if _break_timer <= 0.0:
			is_resolve_broken = false
			resolve = MAX_RESOLVE
			stats_changed.emit()

	velocity = _knockback_velocity
	move_and_slide()
	_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, delta * 1450.0)
	_clamp_to_arena()
	queue_redraw()


func _clamp_to_arena() -> void:
	var bounds := ArenaBackdrop.PLAYABLE_RECT.grow(-48.0)
	global_position.x = clampf(global_position.x, bounds.position.x, bounds.end.x)
	global_position.y = clampf(global_position.y, bounds.position.y, bounds.end.y)


func _draw() -> void:
	draw_set_transform(Vector2(0.0, 32.0), 0.0, Vector2(1.45, 0.38))
	draw_circle(Vector2.ZERO, 33.0, Color(0.0, 0.0, 0.0, 0.36))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	var shell := Color("d6c8a6")
	if is_resolve_broken:
		shell = Color("f5b84e")
	if _hit_flash > 0.0:
		shell = shell.lerp(Color.WHITE, _hit_flash)

	var body := PackedVector2Array([
		Vector2(-31.0, 31.0),
		Vector2(-37.0, -4.0),
		Vector2(-21.0, -38.0),
		Vector2(21.0, -38.0),
		Vector2(37.0, -4.0),
		Vector2(31.0, 31.0),
	])
	draw_colored_polygon(body, Color("374149"))
	draw_polyline(body + PackedVector2Array([body[0]]), shell, 5.0, true)
	draw_circle(Vector2(0.0, -3.0), 18.0, Color("10181e"))
	draw_circle(Vector2(0.0, -3.0), 8.0, Color("e64f3d") if not is_resolve_broken else Color("fff0a8"))
	draw_line(Vector2(-22.0, 16.0), Vector2(22.0, 16.0), shell.darkened(0.2), 4.0, true)

	if is_resolve_broken:
		draw_arc(Vector2.ZERO, 51.0, -2.7, -0.45, 24, Color("fff0a8"), 5.0, true)
		draw_arc(Vector2.ZERO, 51.0, 0.45, 2.7, 24, Color("fff0a8"), 5.0, true)

	_draw_bar(Vector2(-43.0, -63.0), 86.0, health / MAX_HEALTH, Color("e65b49"))
	_draw_bar(Vector2(-43.0, -53.0), 86.0, resolve / MAX_RESOLVE, Color("54d4ce"))


func _draw_bar(at: Vector2, width: float, ratio: float, color: Color) -> void:
	draw_rect(Rect2(at, Vector2(width, 5.0)), Color(0.02, 0.03, 0.04, 0.88))
	draw_rect(Rect2(at + Vector2.ONE, Vector2((width - 2.0) * clampf(ratio, 0.0, 1.0), 3.0)), color)