class_name ReliquaryPursuer
extends CharacterBody2D


signal attack_connected(at: Vector2, direction: Vector2, packet: DamagePacket, intensity: float)
signal effect_requested(effect_id: StringName, at: Vector2, direction: Vector2, size_scale: float)
signal audio_requested(cue: StringName, power: float)
signal stats_changed
signal defeated(enemy: ReliquaryPursuer)

enum State {
	CHASE,
	WINDUP,
	ACTIVE,
	RECOVERY,
	STAGGER,
	DEAD,
}

const ATTACK_REACH := 106.0
const ATTACK_HALF_WIDTH := 47.0

var display_name := "Ashen Pursuer"
var max_health := 118.0
var max_resolve := 86.0
var health := 118.0
var resolve := 86.0
var move_speed := 194.0
var attack_damage := 22.0
var windup_duration := 0.52

var _player: Node2D
var _variant := 0
var _state := State.CHASE
var _state_time := 0.0
var _facing := Vector2.LEFT
var _attack_area: Area2D
var _attack_shape: CollisionShape2D
var _attack_hit := false
var _knockback_velocity := Vector2.ZERO
var _hit_flash := 0.0
var _curse_stacks := 0
var _curse_remaining := 0.0
var _curse_tick := 1.0
var _death_timer := 0.0
var _telegraph_time := 0.0


func configure(player: Node2D, variant: int) -> void:
	_player = player
	_variant = posmod(variant, 3)
	match _variant:
		0:
			display_name = "Ashen Pursuer"
			max_health = 118.0
			max_resolve = 86.0
			move_speed = 205.0
			attack_damage = 21.0
			windup_duration = 0.48
		1:
			display_name = "Iron Penitent"
			max_health = 168.0
			max_resolve = 122.0
			move_speed = 154.0
			attack_damage = 31.0
			windup_duration = 0.70
		2:
			display_name = "Relic Stalker"
			max_health = 98.0
			max_resolve = 72.0
			move_speed = 238.0
			attack_damage = 18.0
			windup_duration = 0.38
	health = max_health
	resolve = max_resolve


func _ready() -> void:
	add_to_group(&"enemies")
	collision_layer = 2
	collision_mask = 1 | 4
	z_index = 10

	var body_shape := CollisionShape2D.new()
	var body_circle := CircleShape2D.new()
	body_circle.radius = 31.0 if _variant != 1 else 37.0
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
	hurt_circle.radius = 36.0 if _variant != 1 else 43.0
	hurt_shape.shape = hurt_circle
	hurt_shape.position = Vector2(0.0, 4.0)
	hurtbox.add_child(hurt_shape)

	_attack_area = Area2D.new()
	_attack_area.name = "EnemyAttackArea"
	_attack_area.collision_layer = 32
	_attack_area.collision_mask = 64
	_attack_area.monitoring = false
	_attack_area.monitorable = false
	add_child(_attack_area)
	_attack_shape = CollisionShape2D.new()
	var strike_rectangle := RectangleShape2D.new()
	strike_rectangle.size = Vector2(ATTACK_REACH, ATTACK_HALF_WIDTH * 2.0)
	_attack_shape.shape = strike_rectangle
	_attack_shape.position = Vector2(ATTACK_REACH * 0.5, 0.0)
	_attack_area.add_child(_attack_shape)
	stats_changed.emit()
	queue_redraw()


func _physics_process(delta: float) -> void:
	_hit_flash = maxf(0.0, _hit_flash - delta * 7.0)
	_telegraph_time += delta
	_tick_curse(delta)
	if _state == State.DEAD:
		_update_death(delta)
		queue_redraw()
		return
	if not is_instance_valid(_player) or not bool(_player.call(&"is_alive")):
		velocity = Vector2.ZERO
		queue_redraw()
		return

	var to_player := _player.global_position - global_position
	if not to_player.is_zero_approx():
		_facing = to_player.normalized()
	match _state:
		State.CHASE:
			velocity = _facing * move_speed + _knockback_velocity
			if to_player.length() <= ATTACK_REACH * 0.88:
				_begin_windup()
		State.WINDUP:
			velocity = _knockback_velocity * 0.25
			_state_time -= delta
			if _state_time <= 0.0:
				_begin_active()
		State.ACTIVE:
			velocity = _facing * 210.0 + _knockback_velocity * 0.15
			_apply_attack()
			_state_time -= delta
			if _state_time <= 0.0:
				_attack_area.monitoring = false
				_state_time = 0.58 if _variant == 1 else 0.42
				_state = State.RECOVERY
		State.RECOVERY:
			velocity = _knockback_velocity * 0.35
			_state_time -= delta
			if _state_time <= 0.0:
				_state = State.CHASE
		State.STAGGER:
			velocity = _knockback_velocity
			_state_time -= delta
			if _state_time <= 0.0:
				_state = State.CHASE
		State.DEAD:
			pass

	move_and_slide()
	_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, delta * 1250.0)
	_clamp_to_arena()
	queue_redraw()


func _begin_windup() -> void:
	_state = State.WINDUP
	_state_time = windup_duration
	_attack_area.rotation = _facing.angle()
	audio_requested.emit(&"enemy_windup", float(_variant) / 2.0)


func _begin_active() -> void:
	_state = State.ACTIVE
	_state_time = 0.12
	_attack_hit = false
	_attack_area.rotation = _facing.angle()
	_attack_area.monitoring = true
	audio_requested.emit(&"enemy_swing", float(_variant) / 2.0)


func _apply_attack() -> void:
	if _attack_hit:
		return
	for hurtbox: Area2D in _attack_area.get_overlapping_areas():
		var target := hurtbox.get_parent()
		if target != _player:
			continue
		_attack_hit = true
		var packet := DamagePacket.enemy_melee(self, attack_damage)
		var direction := (_player.global_position - global_position).normalized()
		DamageResolver.apply(_player, packet, direction)
		attack_connected.emit(_player.global_position - direction * 22.0, direction, packet, clampf(attack_damage / 32.0, 0.35, 1.0))
		return


func receive_hit(packet: DamagePacket, direction: Vector2) -> float:
	if _state == State.DEAD:
		return 0.0
	var before := health
	health = maxf(0.0, health - packet.health_damage)
	resolve = maxf(0.0, resolve - packet.resolve_damage)
	_knockback_velocity += direction.normalized() * packet.knockback_force
	_hit_flash = 1.0
	if resolve <= 0.0 and health > 0.0:
		resolve = max_resolve * 0.42
		_attack_area.monitoring = false
		_state = State.STAGGER
		_state_time = 1.15 if _variant == 1 else 0.92
		audio_requested.emit(&"enemy_break", 0.8)
	if health <= 0.0:
		_begin_death()
	stats_changed.emit()
	return before - health


func apply_curse(stacks: int, duration: float) -> void:
	if _state == State.DEAD:
		return
	_curse_stacks = clampi(_curse_stacks + stacks, 1, 5)
	_curse_remaining = maxf(_curse_remaining, duration)
	_curse_tick = minf(_curse_tick, 0.55)
	effect_requested.emit(&"kat_curse", global_position, Vector2.UP, 0.88 + 0.09 * float(_curse_stacks))
	stats_changed.emit()


func _tick_curse(delta: float) -> void:
	if _curse_stacks <= 0 or _state == State.DEAD:
		return
	_curse_remaining -= delta
	_curse_tick -= delta
	if _curse_tick <= 0.0:
		_curse_tick += 1.0
		var tick_damage := 2.5 + 1.6 * float(_curse_stacks)
		health = maxf(0.0, health - tick_damage)
		effect_requested.emit(&"kat_curse", global_position, Vector2.UP, 0.70)
		if is_instance_valid(_player) and _player.has_method(&"heal"):
			_player.call(&"heal", tick_damage * 0.42)
		if is_instance_valid(_player) and _player.has_method(&"gain_vitality"):
			_player.call(&"gain_vitality", 1.8 * float(_curse_stacks))
		if health <= 0.0:
			_begin_death()
	if _curse_remaining <= 0.0:
		_curse_stacks = 0
		_curse_remaining = 0.0
	stats_changed.emit()


func pull_toward(point: Vector2, force: float) -> void:
	var direction := (point - global_position).normalized()
	_knockback_velocity += direction * force


func _begin_death() -> void:
	if _state == State.DEAD:
		return
	_state = State.DEAD
	_death_timer = 0.72
	_attack_area.monitoring = false
	collision_layer = 0
	collision_mask = 0
	effect_requested.emit(&"kat_curse", global_position, Vector2.UP, 1.35)
	audio_requested.emit(&"enemy_defeat", 0.7)
	defeated.emit(self)


func _update_death(delta: float) -> void:
	_death_timer -= delta
	rotation += delta * 2.8
	scale = Vector2.ONE * clampf(_death_timer / 0.72, 0.05, 1.0)
	modulate.a = clampf(_death_timer / 0.50, 0.0, 1.0)
	if _death_timer <= 0.0:
		queue_free()


func _clamp_to_arena() -> void:
	var bounds := ArenaBackdrop.PLAYABLE_RECT.grow(-44.0)
	global_position.x = clampf(global_position.x, bounds.position.x, bounds.end.x)
	global_position.y = clampf(global_position.y, bounds.position.y, bounds.end.y)


func is_alive() -> bool:
	return _state != State.DEAD


func is_cursed() -> bool:
	return _curse_stacks > 0


func get_curse_stacks() -> int:
	return _curse_stacks


func _draw() -> void:
	draw_set_transform(Vector2(0.0, 25.0), 0.0, Vector2(1.3, 0.38))
	draw_circle(Vector2.ZERO, 29.0 if _variant != 1 else 35.0, Color(0.0, 0.0, 0.0, 0.35))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	var base_colors := [Color("875846"), Color("606c73"), Color("5d394e")]
	var accent_colors := [Color("e39a55"), Color("b9d0ca"), Color("e05a82")]
	var body_color: Color = base_colors[_variant]
	if _hit_flash > 0.0:
		body_color = body_color.lerp(Color.WHITE, _hit_flash)
	var right := _facing.orthogonal()
	var body_size := 33.0 if _variant != 1 else 40.0
	var body := PackedVector2Array([
		-_facing * body_size + right * body_size * 0.72,
		-_facing * body_size * 1.18,
		-_facing * body_size - right * body_size * 0.72,
		_facing * body_size * 0.75 - right * body_size * 0.62,
		_facing * body_size,
		_facing * body_size * 0.75 + right * body_size * 0.62,
	])
	draw_colored_polygon(body, body_color)
	draw_polyline(body + PackedVector2Array([body[0]]), accent_colors[_variant], 4.0, true)
	draw_circle(_facing * 6.0, 13.0, Color("15171c"))
	draw_circle(_facing * 11.0, 5.0, accent_colors[_variant])

	if _variant == 1:
		draw_arc(_facing * 14.0 + right * 21.0, 24.0, _facing.angle() - 1.1, _facing.angle() + 1.1, 24, Color("d6e1d9"), 7.0, true)
	else:
		draw_line(_facing * 20.0 - right * 18.0, _facing * 59.0 - right * 18.0, accent_colors[_variant], 5.0, true)

	if _state == State.WINDUP:
		var windup_ratio := 1.0 - clampf(_state_time / windup_duration, 0.0, 1.0)
		var telegraph_alpha := 0.18 + windup_ratio * 0.32 + sin(_telegraph_time * 28.0) * 0.06
		var corners := PackedVector2Array([
			right * ATTACK_HALF_WIDTH,
			_facing * ATTACK_REACH + right * ATTACK_HALF_WIDTH,
			_facing * ATTACK_REACH - right * ATTACK_HALF_WIDTH,
			-right * ATTACK_HALF_WIDTH,
		])
		draw_colored_polygon(corners, Color(0.95, 0.15, 0.12, telegraph_alpha))
		draw_polyline(corners + PackedVector2Array([corners[0]]), Color(1.0, 0.63, 0.35, 0.70), 2.0, true)
	if _state == State.ACTIVE:
		draw_arc(Vector2.ZERO, ATTACK_REACH * 0.82, _facing.angle() - 0.62, _facing.angle() + 0.62, 26, Color(1.0, 0.48, 0.28, 0.88), 7.0, true)

	if _curse_stacks > 0:
		for stack_index: int in _curse_stacks:
			var angle := _telegraph_time * 1.4 + TAU * float(stack_index) / float(_curse_stacks)
			draw_circle(Vector2.from_angle(angle) * 43.0, 4.0, Color("ef3b63"))
	_draw_bar(Vector2(-38.0, -57.0), 76.0, health / max_health, Color("e65b49"))
	_draw_bar(Vector2(-38.0, -49.0), 76.0, resolve / max_resolve, Color("54d4ce"))


func _draw_bar(at: Vector2, width: float, ratio: float, color: Color) -> void:
	draw_rect(Rect2(at, Vector2(width, 4.0)), Color(0.02, 0.03, 0.04, 0.86))
	draw_rect(Rect2(at + Vector2.ONE, Vector2((width - 2.0) * clampf(ratio, 0.0, 1.0), 2.0)), color)