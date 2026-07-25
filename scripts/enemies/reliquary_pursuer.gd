class_name ReliquaryPursuer
extends CharacterBody2D


const EnemyProjectileScript := preload("res://scripts/enemies/enemy_projectile.gd")

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

enum Role {
	RAIDER,
	BULWARK,
	BLOODRUNNER,
	BONE_ARCANIST,
	WARCALLER,
	GRAVE_DEADEYE,
}

const ATTACK_REACH := 106.0
const ATTACK_HALF_WIDTH := 47.0
const ROLE_COUNT := 6
const BULWARK_SLAM_RADIUS := 132.0
const BLOODRUNNER_CHARGE_DISTANCE := 270.0
const BLOODRUNNER_CHARGE_SPEED := 430.0
const BLOODRUNNER_HITBOX_REACH := 58.0
const WARCALLER_PULSE_RADIUS := 340.0
const HORDE_SEPARATION_RADIUS := 76.0
const RANGED_SEPARATION_RADIUS := 184.0
const RANGED_BODY_SEPARATION_RADIUS := 112.0
const SPRITE_BASE_POSITION := Vector2(0.0, -17.0)
const ROLE_ACCENTS := [
	Color("e39a55"),
	Color("d9c36f"),
	Color("ef526f"),
	Color("68b9ff"),
	Color("7ee081"),
	Color("d69cff"),
]
const THREAT_COLOR := Color("ff654f")
const THREAT_HIGHLIGHT := Color("ffd07a")
const ROLE_SPRITES := [
	{&"idle": preload("res://assets/enemies/orc_raider_idle.png"), &"run": preload("res://assets/enemies/orc_raider_run.png")},
	{&"idle": preload("res://assets/enemies/orc_warrior_idle.png"), &"run": preload("res://assets/enemies/orc_warrior_run.png")},
	{&"idle": preload("res://assets/enemies/orc_rogue_idle.png"), &"run": preload("res://assets/enemies/orc_rogue_run.png")},
	{&"idle": preload("res://assets/enemies/skeleton_mage_idle.png"), &"run": preload("res://assets/enemies/skeleton_mage_run.png")},
	{&"idle": preload("res://assets/enemies/orc_shaman_idle.png"), &"run": preload("res://assets/enemies/orc_shaman_run.png")},
	{&"idle": preload("res://assets/enemies/skeleton_rogue_idle.png"), &"run": preload("res://assets/enemies/skeleton_rogue_run.png")},
]

var display_name := "Ashen Raider"
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
var _sprite: AnimatedSprite2D
var _sprite_base_scale := Vector2.ONE * 2.25
var _attack_hit := false
var _knockback_velocity := Vector2.ZERO
var _hit_flash := 0.0
var _curse_stacks := 0
var _curse_remaining := 0.0
var _curse_tick := 1.0
var _control_lock_remaining := 0.0
var _mental_focus := 0
var _focus_remaining := 0.0
var _slow_scale := 1.0
var _slow_remaining := 0.0
var _pierce_marks := 0
var _pierce_mark_remaining := 0.0
var _death_timer := 0.0
var _telegraph_time := 0.0
var _telegraph_reach := ATTACK_REACH
var _avoidance_direction := Vector2.ZERO
var _avoidance_time := 0.0
var _support_boost_remaining := 0.0
var _support_pulse_time := 0.0
var _attack_lockout := 0.0
var _tactical_angle := 0.0
var _orbit_direction := 1.0
var _reposition_remaining := 0.0
var _death_lean := 1.0


func configure(player: Node2D, variant: int) -> void:
	_player = player
	_variant = posmod(variant, Role.size())
	match _variant:
		Role.RAIDER:
			display_name = "Ashen Raider"
			max_health = 118.0
			max_resolve = 86.0
			move_speed = 158.0
			attack_damage = 21.0
			windup_duration = 0.56
		Role.BULWARK:
			display_name = "Iron Bulwark"
			max_health = 260.0
			max_resolve = 190.0
			move_speed = 84.0
			attack_damage = 42.0
			windup_duration = 0.92
		Role.BLOODRUNNER:
			display_name = "Bloodrunner"
			max_health = 82.0
			max_resolve = 60.0
			move_speed = 192.0
			attack_damage = 16.0
			windup_duration = 0.42
		Role.BONE_ARCANIST:
			display_name = "Bone Arcanist"
			max_health = 94.0
			max_resolve = 80.0
			move_speed = 112.0
			attack_damage = 24.0
			windup_duration = 0.72
		Role.WARCALLER:
			display_name = "Warcaller"
			max_health = 132.0
			max_resolve = 118.0
			move_speed = 98.0
			attack_damage = 14.0
			windup_duration = 0.86
		Role.GRAVE_DEADEYE:
			display_name = "Grave Deadeye"
			max_health = 88.0
			max_resolve = 68.0
			move_speed = 136.0
			attack_damage = 18.0
			windup_duration = 0.58
	health = max_health
	resolve = max_resolve


func _ready() -> void:
	add_to_group(&"enemies")
	collision_layer = 2
	collision_mask = 1 | 4
	z_index = 10
	_build_sprite()

	var body_shape := CollisionShape2D.new()
	var body_circle := CircleShape2D.new()
	body_circle.radius = 38.0 if _variant == Role.BULWARK else 29.0
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
	hurt_circle.radius = 45.0 if _variant == Role.BULWARK else 35.0
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
	_attack_lockout = 0.55 + 0.14 * float((int(get_instance_id()) + _variant * 3) % 8)
	if _is_ranged_role() and is_instance_valid(_player):
		var away_from_player := global_position - _player.global_position
		_tactical_angle = away_from_player.angle() if not away_from_player.is_zero_approx() else 0.0
		_orbit_direction = -1.0 if get_instance_id() % 2 == 0 else 1.0
		_tactical_angle += _orbit_direction * (0.28 + 0.07 * float(get_instance_id() % 4))
	stats_changed.emit()
	queue_redraw()


func _build_sprite() -> void:
	var sprite_data: Dictionary = ROLE_SPRITES[_variant]
	var sprite_frames := SpriteFrames.new()
	sprite_frames.remove_animation(&"default")
	_add_sheet_animation(sprite_frames, &"idle", sprite_data[&"idle"] as Texture2D, 4, Vector2i(32, 32), 5.0)
	_add_sheet_animation(sprite_frames, &"run", sprite_data[&"run"] as Texture2D, 6, Vector2i(64, 64), 10.0)
	_sprite = AnimatedSprite2D.new()
	_sprite.name = "EnemySprite"
	_sprite.sprite_frames = sprite_frames
	_sprite.animation = &"idle"
	_sprite_base_scale = Vector2.ONE * (2.45 if _variant == Role.BULWARK else 2.25)
	_sprite.position = SPRITE_BASE_POSITION
	_sprite.scale = _sprite_base_scale
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.play()
	add_child(_sprite)


func _add_sheet_animation(frames: SpriteFrames, animation: StringName, texture: Texture2D, frame_count: int, frame_size: Vector2i, speed: float) -> void:
	frames.add_animation(animation)
	frames.set_animation_loop(animation, true)
	frames.set_animation_speed(animation, speed)
	for frame_index: int in frame_count:
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(frame_size.x * frame_index, 0, frame_size.x, frame_size.y)
		frames.add_frame(animation, atlas)


func _physics_process(delta: float) -> void:
	_hit_flash = maxf(0.0, _hit_flash - delta * 7.0)
	_telegraph_time += delta
	_tick_curse(delta)
	_tick_external_control(delta)
	_support_boost_remaining = maxf(0.0, _support_boost_remaining - delta)
	_support_pulse_time = maxf(0.0, _support_pulse_time - delta)
	_attack_lockout = maxf(0.0, _attack_lockout - delta)
	_reposition_remaining = maxf(0.0, _reposition_remaining - delta)
	if _state == State.DEAD:
		_update_death(delta)
		queue_redraw()
		return
	if not is_instance_valid(_player) or not bool(_player.call(&"is_alive")):
		velocity = Vector2.ZERO
		queue_redraw()
		return
	var player_concealed := _player.has_method(&"is_concealed") and bool(_player.call(&"is_concealed"))
	if player_concealed and _state == State.WINDUP:
		_attack_area.monitoring = false
		_attack_hit = true
		_state = State.CHASE
		_state_time = 0.0
		_attack_lockout = maxf(_attack_lockout, 0.75)
	if _control_lock_remaining > 0.0:
		velocity = Vector2.ZERO
		_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, delta * 1800.0)
		queue_redraw()
		return

	var to_player := _player.global_position - global_position
	if (_state == State.CHASE or (_state == State.RECOVERY and _is_ranged_role())) and not to_player.is_zero_approx():
		_facing = to_player.normalized()
	_avoidance_time = maxf(0.0, _avoidance_time - delta)
	match _state:
		State.CHASE:
			var chase_direction := _get_chase_direction(to_player)
			var boost_speed := 1.10 if _support_boost_remaining > 0.0 else 1.0
			velocity = chase_direction * move_speed * boost_speed * _slow_scale * (0.34 if player_concealed else 1.0) + _knockback_velocity
			if not player_concealed and _attack_lockout <= 0.0 and _should_begin_attack(to_player.length()):
				_begin_windup()
		State.WINDUP:
			velocity = _knockback_velocity * 0.25
			_state_time -= delta
			if _state_time <= 0.0:
				_begin_active()
		State.ACTIVE:
			match _variant:
				Role.RAIDER:
					velocity = _facing * 164.0 + _knockback_velocity * 0.15
				Role.BLOODRUNNER:
					velocity = _facing * BLOODRUNNER_CHARGE_SPEED + _knockback_velocity * 0.08
				_:
					velocity = _knockback_velocity * 0.15
			_apply_attack()
			_state_time -= delta
			if _state_time <= 0.0:
				_attack_area.monitoring = false
				_state_time = _get_recovery_duration()
				_state = State.RECOVERY
		State.RECOVERY:
			if _is_ranged_role() and _reposition_remaining > 0.0:
				var reposition_direction := _get_chase_direction(to_player)
				velocity = reposition_direction * move_speed * 0.78 * _slow_scale + _knockback_velocity * 0.35
			else:
				velocity = _knockback_velocity * 0.35
			_state_time -= delta
			if _state_time <= 0.0:
				_attack_lockout = 0.35 + 0.13 * float((int(get_instance_id()) + _variant) % 6)
				_state = State.CHASE
		State.STAGGER:
			velocity = _knockback_velocity
			_state_time -= delta
			if _state_time <= 0.0:
				_state = State.CHASE
		State.DEAD:
			pass

	move_and_slide()
	if _state == State.CHASE and get_slide_collision_count() > 0:
		var collision := get_slide_collision(0)
		if collision.get_collider() is StaticBody2D:
			var tangent := collision.get_normal().orthogonal()
			if tangent.dot(to_player) < 0.0:
				tangent = -tangent
			_avoidance_direction = tangent * 0.92
			_avoidance_time = 0.52
	_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, delta * 1250.0)
	_clamp_to_arena()
	_update_sprite(delta)
	queue_redraw()


func _get_chase_direction(to_player: Vector2) -> Vector2:
	var desired_direction := _facing
	if _avoidance_time > 0.0:
		desired_direction = (_facing * 0.38 + _avoidance_direction).normalized()
	elif _is_ranged_role():
		desired_direction = _get_ranged_tactical_direction(to_player)
	else:
		var distance := to_player.length()
		var preferred_min := 0.0
		var preferred_max := 0.0
		match _variant:
			Role.RAIDER:
				preferred_min = 76.0
				preferred_max = 122.0
			Role.BULWARK:
				preferred_min = 102.0
				preferred_max = 152.0
			Role.BLOODRUNNER:
				preferred_min = 220.0
				preferred_max = 320.0
			Role.WARCALLER:
				preferred_min = 360.0
				preferred_max = 530.0
		if preferred_max > 0.0:
			if distance < preferred_min:
				desired_direction = -_facing
			elif distance <= preferred_max:
				var strafe_sign := -1.0 if get_instance_id() % 2 == 0 else 1.0
				desired_direction = _facing.orthogonal() * strafe_sign
	var separation := _get_horde_separation_direction()
	if separation.is_zero_approx():
		return desired_direction
	var separation_weight := 1.45 if _is_ranged_role() else 0.90
	var blended := desired_direction + separation * separation_weight
	return separation if blended.is_zero_approx() else blended.normalized()


func _get_ranged_tactical_direction(to_player: Vector2) -> Vector2:
	if to_player.is_zero_approx():
		return Vector2.from_angle(_tactical_angle)
	var distance := to_player.length()
	var toward_player := to_player / distance
	var orbit_direction := toward_player.orthogonal() * _orbit_direction
	var preferred_range := _get_ranged_preferred_range()
	var preferred_distance := (preferred_range.x + preferred_range.y) * 0.5
	var moving_slot_angle := _tactical_angle + _telegraph_time * 0.10 * _orbit_direction
	var slot_position := _player.global_position + Vector2.from_angle(moving_slot_angle) * preferred_distance
	var to_slot := slot_position - global_position
	var slot_direction := to_slot.normalized() if not to_slot.is_zero_approx() else orbit_direction
	if distance > preferred_range.y + 120.0:
		return (toward_player * 0.90 + slot_direction * 0.28).normalized()
	if distance > preferred_range.y:
		return (toward_player * 0.72 + slot_direction * 0.48).normalized()
	if distance < preferred_range.x:
		return (-toward_player * 0.82 + orbit_direction * 0.56).normalized()
	var slot_weight := 0.82 if _reposition_remaining > 0.0 else 0.56
	var orbit_weight := 0.78 if _reposition_remaining > 0.0 else 0.42
	return (slot_direction * slot_weight + orbit_direction * orbit_weight).normalized()


func _get_ranged_preferred_range() -> Vector2:
	return Vector2(280.0, 430.0) if _variant == Role.BONE_ARCANIST else Vector2(350.0, 510.0)


func _is_ranged_role() -> bool:
	return _variant == Role.BONE_ARCANIST or _variant == Role.GRAVE_DEADEYE


func _get_horde_separation_direction() -> Vector2:
	var separation := Vector2.ZERO
	for enemy_node: Node in get_tree().get_nodes_in_group(&"enemies"):
		if enemy_node == self or not enemy_node is ReliquaryPursuer:
			continue
		var other := enemy_node as ReliquaryPursuer
		if not other.is_alive():
			continue
		var offset := global_position - other.global_position
		var distance := offset.length()
		var separation_radius := HORDE_SEPARATION_RADIUS
		if _is_ranged_role():
			separation_radius = RANGED_SEPARATION_RADIUS if other._is_ranged_role() else RANGED_BODY_SEPARATION_RADIUS
		if distance >= separation_radius:
			continue
		if distance < 0.01:
			var lower_id := mini(get_instance_id(), other.get_instance_id())
			offset = Vector2.from_angle(float((lower_id * 37) % 360) * PI / 180.0)
			if get_instance_id() > other.get_instance_id():
				offset = -offset
			distance = 0.01
		separation += offset.normalized() * (1.0 - distance / separation_radius)
	return separation.normalized() if not separation.is_zero_approx() else Vector2.ZERO


func _should_begin_attack(distance: float) -> bool:
	match _variant:
		Role.RAIDER:
			return distance <= 94.0
		Role.BULWARK:
			return distance <= BULWARK_SLAM_RADIUS * 0.90
		Role.BLOODRUNNER:
			return distance <= BLOODRUNNER_CHARGE_DISTANCE + BLOODRUNNER_HITBOX_REACH
		Role.BONE_ARCANIST:
			return distance >= 235.0 and distance <= 475.0
		Role.WARCALLER:
			return distance <= 570.0
		Role.GRAVE_DEADEYE:
			return distance >= 310.0 and distance <= 545.0
	return false


func _update_sprite(delta: float) -> void:
	if not is_instance_valid(_sprite):
		return
	var moving_state := _state == State.CHASE or (_state == State.RECOVERY and _is_ranged_role() and _reposition_remaining > 0.0)
	var moving := moving_state and velocity.length_squared() > 400.0
	var desired_animation := &"run" if moving else &"idle"
	if _sprite.animation != desired_animation:
		_sprite.play(desired_animation)
	_sprite.speed_scale = clampf(velocity.length() / maxf(1.0, move_speed), 0.78, 1.35) if moving else 0.88
	_sprite.flip_h = _facing.x < 0.0
	var target_position := SPRITE_BASE_POSITION
	var target_rotation := 0.0
	var target_scale := _sprite_base_scale
	var gait_phase := _telegraph_time * (9.0 + minf(4.0, velocity.length() / 70.0))
	match _state:
		State.CHASE:
			if moving:
				var gait := sin(gait_phase)
				target_position.y -= absf(gait) * 1.8
				target_position.x += gait * 0.7
				target_rotation = clampf(velocity.y / maxf(1.0, move_speed), -1.0, 1.0) * 0.035
				target_scale *= Vector2(1.0 + gait * 0.018, 1.0 - gait * 0.018)
		State.WINDUP:
			var windup_ratio := 1.0 - clampf(_state_time / maxf(0.01, windup_duration), 0.0, 1.0)
			var anticipation := sin(windup_ratio * PI * 0.5)
			target_position -= _facing * (2.0 + anticipation * 4.5)
			target_position.y -= anticipation * 1.5
			target_rotation = _facing.y * 0.065 * anticipation
			target_scale *= Vector2(1.0 - anticipation * 0.055, 1.0 + anticipation * 0.055)
		State.ACTIVE:
			var active_duration := BLOODRUNNER_CHARGE_DISTANCE / BLOODRUNNER_CHARGE_SPEED if _variant == Role.BLOODRUNNER else 0.12
			var active_ratio := 1.0 - clampf(_state_time / active_duration, 0.0, 1.0)
			var action_curve := sin(active_ratio * PI)
			target_position += _facing * (5.0 + action_curve * 5.0)
			target_rotation = -_facing.y * 0.075 * action_curve
			target_scale *= Vector2(1.0 + action_curve * 0.10, 1.0 - action_curve * 0.075)
		State.RECOVERY:
			if moving:
				var recovery_gait := sin(gait_phase)
				target_position.y -= absf(recovery_gait) * 1.4
				target_rotation = clampf(velocity.y / maxf(1.0, move_speed), -1.0, 1.0) * 0.03
			else:
				var settle_ratio := clampf(_state_time / maxf(0.01, _get_recovery_duration()), 0.0, 1.0)
				target_position -= _facing * sin(settle_ratio * PI) * 2.0
				target_rotation = _facing.y * sin(settle_ratio * PI) * 0.025
		State.STAGGER:
			var stagger_wave := sin(_telegraph_time * 34.0)
			target_position.x += stagger_wave * 3.0
			target_rotation = stagger_wave * 0.07
			target_scale *= Vector2(1.06, 0.94)
		State.DEAD:
			pass
	var blend := clampf(1.0 - exp(-maxf(0.0, delta) * 18.0), 0.0, 1.0)
	_sprite.position = _sprite.position.lerp(target_position, blend)
	_sprite.rotation = lerp_angle(_sprite.rotation, target_rotation, blend)
	_sprite.scale = _sprite.scale.lerp(target_scale, blend)
	_sprite.modulate = Color.WHITE.lerp(Color("fff2b8"), _hit_flash)


func _begin_windup() -> void:
	_state = State.WINDUP
	_state_time = windup_duration
	_telegraph_reach = ATTACK_REACH
	if is_instance_valid(_player):
		var target_distance := global_position.distance_to(_player.global_position)
		if _variant == Role.BONE_ARCANIST:
			_telegraph_reach = clampf(target_distance, 235.0, 475.0)
		elif _variant == Role.GRAVE_DEADEYE:
			_telegraph_reach = clampf(target_distance, 310.0, 545.0)
	_configure_attack_shape()
	_attack_area.rotation = _facing.angle()
	audio_requested.emit(&"enemy_windup", float(_variant) / float(ROLE_COUNT - 1))


func _configure_attack_shape() -> void:
	if _variant == Role.BULWARK:
		var slam_circle := CircleShape2D.new()
		slam_circle.radius = BULWARK_SLAM_RADIUS
		_attack_shape.shape = slam_circle
		_attack_shape.position = Vector2.ZERO
		return
	var strike_rectangle := RectangleShape2D.new()
	match _variant:
		Role.BLOODRUNNER:
			strike_rectangle.size = Vector2(116.0, 68.0)
			_attack_shape.position = Vector2(58.0, 0.0)
		_:
			strike_rectangle.size = Vector2(ATTACK_REACH, ATTACK_HALF_WIDTH * 2.0)
			_attack_shape.position = Vector2(ATTACK_REACH * 0.5, 0.0)
	_attack_shape.shape = strike_rectangle


func _begin_active() -> void:
	_state = State.ACTIVE
	_state_time = BLOODRUNNER_CHARGE_DISTANCE / BLOODRUNNER_CHARGE_SPEED if _variant == Role.BLOODRUNNER else 0.12
	_attack_hit = false
	_attack_area.rotation = _facing.angle()
	_attack_area.monitoring = _variant in [Role.RAIDER, Role.BULWARK, Role.BLOODRUNNER]
	if _is_ranged_role():
		_reposition_remaining = 1.45 if _variant == Role.BONE_ARCANIST else 1.70
		_tactical_angle += _orbit_direction * (0.62 + 0.08 * float(get_instance_id() % 4))
	match _variant:
		Role.BONE_ARCANIST:
			_spawn_projectile(EnemyProjectile.Kind.ARCANE_ORB)
		Role.WARCALLER:
			_perform_support_pulse()
		Role.GRAVE_DEADEYE:
			_spawn_projectile(EnemyProjectile.Kind.DEADEYE_BOLT)
	audio_requested.emit(&"enemy_swing", float(_variant) / float(ROLE_COUNT - 1))


func _spawn_projectile(kind: int) -> void:
	if not is_instance_valid(_player):
		return
	var projectile = EnemyProjectileScript.new()
	var boost_damage := 1.20 if _support_boost_remaining > 0.0 else 1.0
	projectile.configure(self, _player, _facing, kind, attack_damage * boost_damage)
	projectile.attack_connected.connect(_on_projectile_connected)
	get_parent().add_child(projectile)
	projectile.global_position = global_position + _facing * 34.0


func _on_projectile_connected(at: Vector2, direction: Vector2, packet: DamagePacket, intensity: float) -> void:
	attack_connected.emit(at, direction, packet, intensity)


func _perform_support_pulse() -> void:
	_support_pulse_time = 0.72
	for enemy_node: Node in get_tree().get_nodes_in_group(&"enemies"):
		if not enemy_node is ReliquaryPursuer:
			continue
		var ally := enemy_node as ReliquaryPursuer
		if not ally.is_alive() or global_position.distance_to(ally.global_position) > WARCALLER_PULSE_RADIUS:
			continue
		ally.receive_support(ally.max_health * 0.10, 5.0)
	effect_requested.emit(&"kat_heal", global_position, Vector2.UP, 1.35)


func receive_support(heal_amount: float, boost_duration: float) -> void:
	if _state == State.DEAD:
		return
	health = minf(max_health, health + maxf(0.0, heal_amount))
	_support_boost_remaining = maxf(_support_boost_remaining, boost_duration)
	stats_changed.emit()
	queue_redraw()


func _get_recovery_duration() -> float:
	match _variant:
		Role.BULWARK:
			return 2.55
		Role.BLOODRUNNER:
			return 2.20
		Role.BONE_ARCANIST:
			return 2.75
		Role.WARCALLER:
			return 4.35
		Role.GRAVE_DEADEYE:
			return 2.45
	return 1.65


func _apply_attack() -> void:
	if _attack_hit or not _attack_area.monitoring:
		return
	for hurtbox: Area2D in _attack_area.get_overlapping_areas():
		var target := hurtbox.get_parent()
		if target != _player:
			continue
		_attack_hit = true
		var boost_damage := 1.20 if _support_boost_remaining > 0.0 else 1.0
		var packet := DamagePacket.enemy_melee(self, attack_damage * boost_damage)
		var direction := (_player.global_position - global_position).normalized()
		DamageResolver.apply(_player, packet, direction)
		attack_connected.emit(_player.global_position - direction * 22.0, direction, packet, clampf(attack_damage / 32.0, 0.35, 1.0))
		return


func receive_hit(packet: DamagePacket, direction: Vector2) -> float:
	if _state == State.DEAD:
		return 0.0
	var before := health
	var health_damage := packet.health_damage
	if _control_lock_remaining > 0.0:
		health_damage *= get_control_damage_multiplier()
	health = maxf(0.0, health - health_damage)
	resolve = maxf(0.0, resolve - packet.resolve_damage)
	_knockback_velocity += direction.normalized() * packet.knockback_force
	_hit_flash = 1.0
	if resolve <= 0.0 and health > 0.0:
		resolve = max_resolve * 0.42
		_attack_area.monitoring = false
		_state = State.STAGGER
		_state_time = 1.15 if _variant == Role.BULWARK else 0.92
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


func apply_mental_focus(stacks: int, duration := 7.0) -> void:
	if _state == State.DEAD or stacks <= 0:
		return
	_mental_focus = clampi(_mental_focus + stacks, 0, 5)
	_focus_remaining = maxf(_focus_remaining, duration)
	stats_changed.emit()


func apply_control_lock(duration: float) -> void:
	if _state == State.DEAD or duration <= 0.0:
		return
	_control_lock_remaining = maxf(_control_lock_remaining, duration)
	_attack_area.monitoring = false
	_attack_hit = true
	_state = State.CHASE
	velocity = Vector2.ZERO
	stats_changed.emit()


func extend_control_lock(duration: float, maximum_remaining := 6.0) -> void:
	if _state == State.DEAD or _control_lock_remaining <= 0.0 or duration <= 0.0:
		return
	_control_lock_remaining = minf(maximum_remaining, _control_lock_remaining + duration)
	stats_changed.emit()


func apply_temporary_slow(speed_scale: float, duration: float) -> void:
	if _state == State.DEAD or duration <= 0.0:
		return
	_slow_scale = minf(_slow_scale, clampf(speed_scale, 0.20, 1.0))
	_slow_remaining = maxf(_slow_remaining, duration)


func _tick_external_control(delta: float) -> void:
	_control_lock_remaining = maxf(0.0, _control_lock_remaining - delta)
	if _focus_remaining > 0.0:
		_focus_remaining -= delta
		if _focus_remaining <= 0.0:
			_mental_focus = 0
			_focus_remaining = 0.0
	if _slow_remaining > 0.0:
		_slow_remaining -= delta
		if _slow_remaining <= 0.0:
			_slow_scale = 1.0
			_slow_remaining = 0.0
	if _pierce_mark_remaining > 0.0:
		_pierce_mark_remaining -= delta
		if _pierce_mark_remaining <= 0.0:
			_pierce_marks = 0
			_pierce_mark_remaining = 0.0


func apply_pierce_mark(stacks: int, duration := 8.0) -> void:
	if _state == State.DEAD or stacks <= 0:
		return
	_pierce_marks = clampi(_pierce_marks + stacks, 0, 5)
	_pierce_mark_remaining = maxf(_pierce_mark_remaining, duration)
	stats_changed.emit()


func consume_pierce_marks(maximum := 5) -> int:
	if maximum <= 0 or _pierce_marks <= 0:
		return 0
	var consumed := mini(_pierce_marks, maximum)
	_pierce_marks -= consumed
	if _pierce_marks <= 0:
		_pierce_mark_remaining = 0.0
	stats_changed.emit()
	return consumed


func _begin_death() -> void:
	if _state == State.DEAD:
		return
	_state = State.DEAD
	_death_timer = 0.72
	_death_lean = -1.0 if get_instance_id() % 2 == 0 else 1.0
	_attack_area.monitoring = false
	collision_layer = 0
	collision_mask = 0
	effect_requested.emit(&"kat_curse", global_position, Vector2.UP, 1.35)
	audio_requested.emit(&"enemy_defeat", 0.7)
	defeated.emit(self)


func _update_death(delta: float) -> void:
	_death_timer -= delta
	var remaining_ratio := clampf(_death_timer / 0.72, 0.0, 1.0)
	var death_progress := 1.0 - remaining_ratio
	rotation = _death_lean * death_progress * 0.16
	scale = Vector2(1.0 + sin(death_progress * PI) * 0.10, maxf(0.08, 1.0 - death_progress * 0.92))
	modulate.a = clampf(_death_timer / 0.42, 0.0, 1.0)
	if is_instance_valid(_sprite):
		_sprite.position = SPRITE_BASE_POSITION + Vector2(0.0, death_progress * 9.0)
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


func is_control_locked() -> bool:
	return _control_lock_remaining > 0.0


func get_control_lock_remaining() -> float:
	return _control_lock_remaining


func get_mental_focus() -> int:
	return _mental_focus


func get_control_damage_multiplier() -> float:
	return 1.0 + 0.12 * float(_mental_focus)


func get_role() -> int:
	return _variant


func get_attack_style() -> StringName:
	return [&"melee", &"slam", &"rush", &"homing_projectile", &"support", &"fast_projectile"][_variant] as StringName


func get_pierce_marks() -> int:
	return _pierce_marks


func is_attack_winding_up() -> bool:
	return _state == State.WINDUP


func get_facing_direction() -> Vector2:
	return _facing


func _draw() -> void:
	var movement_ratio := clampf(velocity.length() / maxf(1.0, move_speed), 0.0, 1.0)
	draw_set_transform(Vector2(0.0, 25.0), 0.0, Vector2(1.3 + movement_ratio * 0.10, 0.38 - movement_ratio * 0.04))
	draw_circle(Vector2.ZERO, 35.0 if _variant == Role.BULWARK else 29.0, Color(0.0, 0.0, 0.0, 0.31))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if _state == State.DEAD:
		return

	var accent: Color = ROLE_ACCENTS[_variant]
	var right := _facing.orthogonal()
	var role_radius := 39.0 if _variant == Role.BULWARK else 34.0
	draw_arc(Vector2(0.0, 5.0), role_radius, 0.18, 1.05, 12, Color(accent, 0.42), 2.2, true)
	draw_arc(Vector2(0.0, 5.0), role_radius, PI + 0.18, PI + 1.05, 12, Color(accent, 0.42), 2.2, true)
	if _support_boost_remaining > 0.0:
		var boost_rotation := _telegraph_time * 1.8
		draw_arc(Vector2(0.0, 3.0), role_radius + 5.0, boost_rotation, boost_rotation + PI * 0.65, 16, Color("8dff88", 0.50), 2.0, true)

	if _state == State.WINDUP:
		var windup_ratio := 1.0 - clampf(_state_time / windup_duration, 0.0, 1.0)
		var telegraph_alpha := clampf(0.055 + windup_ratio * 0.12, 0.05, 0.18)
		_draw_role_telegraph(right, windup_ratio, telegraph_alpha)
		var progress_color := accent if _variant == Role.WARCALLER else THREAT_HIGHLIGHT
		var progress_start := -PI * 0.5
		var progress_end := progress_start + TAU * maxf(0.025, windup_ratio)
		draw_arc(Vector2(0.0, 3.0), role_radius + 6.0, 0.0, TAU, 32, Color(progress_color, 0.14), 2.0, true)
		draw_arc(Vector2(0.0, 3.0), role_radius + 6.0, progress_start, progress_end, 32, Color(progress_color, 0.86), 3.0, true)
		draw_circle(Vector2(0.0, 3.0) + Vector2.from_angle(progress_end) * (role_radius + 6.0), 2.6, Color(progress_color, 0.95))
	if _state == State.ACTIVE:
		if _variant == Role.BULWARK:
			draw_arc(Vector2.ZERO, BULWARK_SLAM_RADIUS, 0.0, TAU, 48, Color(1.0, 0.48, 0.28, 0.58), 4.0, true)
		elif _variant == Role.BLOODRUNNER:
			draw_line(-_facing * 54.0, _facing * 38.0, Color(1.0, 0.24, 0.32, 0.56), 7.0, true)
		elif _variant == Role.RAIDER:
			draw_arc(Vector2.ZERO, ATTACK_REACH * 0.82, _facing.angle() - 0.62, _facing.angle() + 0.62, 26, Color(1.0, 0.48, 0.28, 0.58), 4.0, true)
	if _support_pulse_time > 0.0:
		var pulse_ratio := 1.0 - _support_pulse_time / 0.72
		draw_arc(Vector2.ZERO, lerpf(48.0, WARCALLER_PULSE_RADIUS, pulse_ratio), 0.0, TAU, 64, Color(0.45, 1.0, 0.48, 0.34 * (1.0 - pulse_ratio)), 2.5, true)

	if _curse_stacks > 0:
		for stack_index: int in _curse_stacks:
			var angle := _telegraph_time * 1.4 + TAU * float(stack_index) / float(_curse_stacks)
			draw_circle(Vector2.from_angle(angle) * 43.0, 4.0, Color("ef3b63"))
	if _control_lock_remaining > 0.0:
		draw_arc(Vector2.ZERO, 47.0, _telegraph_time * 0.8, _telegraph_time * 0.8 + PI * 1.65, 32, Color("65e4ff"), 4.0, true)
		draw_line(Vector2(-29.0, -37.0), Vector2(29.0, -37.0), Color(0.48, 0.92, 1.0, 0.62), 2.0, true)
	if _mental_focus > 0:
		for focus_index: int in _mental_focus:
			draw_circle(Vector2(-16.0 + float(focus_index) * 8.0, -77.0), 3.0, Color("9cf5ff"))
	if _pierce_marks > 0:
		for mark_index: int in _pierce_marks:
			var mark_x := -16.0 + float(mark_index) * 8.0
			draw_colored_polygon(PackedVector2Array([
				Vector2(mark_x, -88.0),
				Vector2(mark_x + 3.5, -83.0),
				Vector2(mark_x, -78.0),
				Vector2(mark_x - 3.5, -83.0),
			]), Color("f4c95d"))
	_draw_vitals(Vector2(-36.0, -65.0), 72.0, accent)


func _draw_role_telegraph(right: Vector2, windup_ratio: float, alpha: float) -> void:
	match _variant:
		Role.RAIDER:
			_draw_lane(right, ATTACK_REACH, ATTACK_HALF_WIDTH, Color(THREAT_COLOR, alpha))
		Role.BULWARK:
			draw_circle(Vector2.ZERO, BULWARK_SLAM_RADIUS, Color(THREAT_COLOR, alpha * 0.34))
			draw_arc(Vector2.ZERO, BULWARK_SLAM_RADIUS, 0.0, TAU, 48, Color(THREAT_HIGHLIGHT, 0.36 + windup_ratio * 0.26), 2.0 + windup_ratio, true)
		Role.BLOODRUNNER:
			_draw_lane(right, BLOODRUNNER_CHARGE_DISTANCE + BLOODRUNNER_HITBOX_REACH, 35.0, Color(THREAT_COLOR, alpha))
		Role.BONE_ARCANIST:
			_draw_lane(right, _telegraph_reach, 17.0, Color(THREAT_COLOR, alpha * 0.76))
			_draw_target_reticle(_facing * _telegraph_reach, 15.0 + windup_ratio * 3.0, Color(ROLE_ACCENTS[_variant], 0.86), windup_ratio)
			draw_circle(_facing * 30.0, 9.0 + windup_ratio * 7.0, Color(ROLE_ACCENTS[_variant], 0.52))
			draw_circle(_facing * 30.0, 3.0 + windup_ratio * 3.0, Color(0.90, 0.97, 1.0, 0.88))
		Role.WARCALLER:
			var sigil_radius := 42.0 + windup_ratio * 18.0
			draw_arc(Vector2.ZERO, sigil_radius, -PI * 0.85, PI * 0.85, 24, Color(0.48, 1.0, 0.52, 0.34 + windup_ratio * 0.22), 2.0, true)
			draw_line(Vector2(-11.0, 0.0), Vector2(11.0, 0.0), Color(0.65, 1.0, 0.62, 0.58), 3.0, true)
			draw_line(Vector2(0.0, -11.0), Vector2(0.0, 11.0), Color(0.65, 1.0, 0.62, 0.58), 3.0, true)
		Role.GRAVE_DEADEYE:
			_draw_lane(right, _telegraph_reach, 10.0, Color(THREAT_COLOR, alpha * 0.90))
			_draw_target_reticle(_facing * _telegraph_reach, 12.0 + windup_ratio * 2.0, Color(ROLE_ACCENTS[_variant], 0.92), windup_ratio)


func _draw_lane(right: Vector2, reach: float, half_width: float, color: Color) -> void:
	var corners := PackedVector2Array([
		right * half_width,
		_facing * reach + right * half_width,
		_facing * reach - right * half_width,
		-right * half_width,
	])
	draw_colored_polygon(corners, Color(color, color.a * 0.42))
	var edge_color := Color(color, minf(0.44, color.a * 2.15))
	draw_line(corners[0], corners[1], edge_color, 1.6, true)
	draw_line(corners[3], corners[2], edge_color, 1.6, true)
	draw_line(corners[1], corners[2], Color(edge_color, edge_color.a * 0.72), 1.2, true)


func _draw_target_reticle(at: Vector2, radius: float, color: Color, progress: float) -> void:
	var rotation_offset := _telegraph_time * 0.65
	for quadrant: int in 4:
		var arc_start := rotation_offset + float(quadrant) * PI * 0.5
		draw_arc(at, radius, arc_start, arc_start + 0.58, 7, color, 2.0, true)
	var cross_size := 4.0 + progress * 3.0
	draw_line(at - Vector2(cross_size, 0.0), at + Vector2(cross_size, 0.0), Color(color, 0.62), 1.2, true)
	draw_line(at - Vector2(0.0, cross_size), at + Vector2(0.0, cross_size), Color(color, 0.62), 1.2, true)
	draw_circle(at, 2.0 + progress * 1.5, Color(THREAT_HIGHLIGHT, 0.84))


func _draw_vitals(at: Vector2, width: float, accent: Color) -> void:
	var frame := Rect2(at - Vector2(3.0, 3.0), Vector2(width + 6.0, 14.0))
	draw_rect(Rect2(frame.position + Vector2(1.5, 2.0), frame.size), Color(0.0, 0.0, 0.0, 0.36))
	draw_rect(frame, Color(0.018, 0.028, 0.034, 0.92))
	draw_rect(frame, Color(accent, 0.46), false, 1.0)
	var health_width := width * clampf(health / maxf(1.0, max_health), 0.0, 1.0)
	var resolve_width := width * clampf(resolve / maxf(1.0, max_resolve), 0.0, 1.0)
	draw_rect(Rect2(at, Vector2(width, 5.0)), Color(0.14, 0.06, 0.07, 0.95))
	if health_width > 0.0:
		draw_rect(Rect2(at, Vector2(health_width, 5.0)), Color("e65b49"))
		draw_line(at + Vector2(0.0, 0.5), at + Vector2(health_width, 0.5), Color(1.0, 0.72, 0.62, 0.62), 1.0)
	draw_rect(Rect2(at + Vector2(0.0, 7.0), Vector2(width, 2.0)), Color(0.04, 0.15, 0.16, 0.95))
	if resolve_width > 0.0:
		draw_rect(Rect2(at + Vector2(0.0, 7.0), Vector2(resolve_width, 2.0)), Color("54d4ce"))
	var pip_center := at + Vector2(-7.0, 4.5)
	draw_colored_polygon(PackedVector2Array([
		pip_center + Vector2(0.0, -4.0),
		pip_center + Vector2(4.0, 0.0),
		pip_center + Vector2(0.0, 4.0),
		pip_center + Vector2(-4.0, 0.0),
	]), accent)