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
var _avoidance_direction := Vector2.ZERO
var _avoidance_time := 0.0
var _support_boost_remaining := 0.0
var _support_pulse_time := 0.0
var _attack_lockout := 0.0


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
	_sprite.position = Vector2(0.0, -17.0)
	_sprite.scale = Vector2.ONE * (2.45 if _variant == Role.BULWARK else 2.25)
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
	if _state == State.CHASE and not to_player.is_zero_approx():
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
	_update_sprite()
	queue_redraw()


func _get_chase_direction(to_player: Vector2) -> Vector2:
	var desired_direction := _facing
	if _avoidance_time > 0.0:
		desired_direction = (_facing * 0.38 + _avoidance_direction).normalized()
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
			Role.BONE_ARCANIST:
				preferred_min = 320.0
				preferred_max = 490.0
			Role.WARCALLER:
				preferred_min = 360.0
				preferred_max = 530.0
			Role.GRAVE_DEADEYE:
				preferred_min = 390.0
				preferred_max = 560.0
		if preferred_max > 0.0:
			if distance < preferred_min:
				desired_direction = -_facing
			elif distance <= preferred_max:
				var strafe_sign := -1.0 if get_instance_id() % 2 == 0 else 1.0
				desired_direction = _facing.orthogonal() * strafe_sign
	var separation := _get_horde_separation_direction()
	if separation.is_zero_approx():
		return desired_direction
	var blended := desired_direction + separation * 0.90
	return separation if blended.is_zero_approx() else blended.normalized()


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
		if distance >= HORDE_SEPARATION_RADIUS:
			continue
		if distance < 0.01:
			offset = Vector2.RIGHT.rotated(float(get_instance_id() % 8) * PI * 0.25)
			distance = 0.01
		separation += offset.normalized() * (1.0 - distance / HORDE_SEPARATION_RADIUS)
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
			return distance <= 510.0
		Role.WARCALLER:
			return distance <= 570.0
		Role.GRAVE_DEADEYE:
			return distance <= 590.0
	return false


func _update_sprite() -> void:
	if not is_instance_valid(_sprite):
		return
	var desired_animation := &"run" if _state == State.CHASE and velocity.length_squared() > 400.0 else &"idle"
	if _sprite.animation != desired_animation:
		_sprite.play(desired_animation)
	_sprite.flip_h = _facing.x < 0.0
	_sprite.modulate = Color.WHITE.lerp(Color("fff2b8"), _hit_flash)


func _begin_windup() -> void:
	_state = State.WINDUP
	_state_time = windup_duration
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
	draw_set_transform(Vector2(0.0, 25.0), 0.0, Vector2(1.3, 0.38))
	draw_circle(Vector2.ZERO, 35.0 if _variant == Role.BULWARK else 29.0, Color(0.0, 0.0, 0.0, 0.35))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	var accent_colors := [Color("e39a55"), Color("d9c36f"), Color("ef526f"), Color("68b9ff"), Color("7ee081"), Color("d69cff")]
	var right := _facing.orthogonal()
	draw_arc(Vector2.ZERO, 39.0 if _variant == Role.BULWARK else 34.0, 0.0, TAU, 28, Color(accent_colors[_variant], 0.38), 2.0, true)

	if _state == State.WINDUP:
		var windup_ratio := 1.0 - clampf(_state_time / windup_duration, 0.0, 1.0)
		var telegraph_alpha := clampf(0.035 + windup_ratio * 0.12 + sin(_telegraph_time * 16.0) * 0.015, 0.025, 0.17)
		_draw_role_telegraph(right, windup_ratio, telegraph_alpha)
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
			draw_circle(Vector2(-16.0 + float(focus_index) * 8.0, -66.0), 3.0, Color("9cf5ff"))
	if _pierce_marks > 0:
		for mark_index: int in _pierce_marks:
			var mark_x := -16.0 + float(mark_index) * 8.0
			draw_colored_polygon(PackedVector2Array([
				Vector2(mark_x, -75.0),
				Vector2(mark_x + 3.5, -70.0),
				Vector2(mark_x, -65.0),
				Vector2(mark_x - 3.5, -70.0),
			]), Color("f4c95d"))
	_draw_bar(Vector2(-38.0, -57.0), 76.0, health / max_health, Color("e65b49"))
	_draw_bar(Vector2(-38.0, -49.0), 76.0, resolve / max_resolve, Color("54d4ce"))


func _draw_role_telegraph(right: Vector2, windup_ratio: float, alpha: float) -> void:
	match _variant:
		Role.RAIDER:
			_draw_lane(right, ATTACK_REACH, ATTACK_HALF_WIDTH, Color(0.95, 0.15, 0.12, alpha))
		Role.BULWARK:
			draw_circle(Vector2.ZERO, BULWARK_SLAM_RADIUS, Color(0.95, 0.15, 0.12, alpha * 0.42))
			draw_arc(Vector2.ZERO, BULWARK_SLAM_RADIUS, 0.0, TAU, 48, Color(1.0, 0.72, 0.28, 0.30 + windup_ratio * 0.20), 2.0 + windup_ratio, true)
		Role.BLOODRUNNER:
			_draw_lane(right, BLOODRUNNER_CHARGE_DISTANCE + BLOODRUNNER_HITBOX_REACH, 35.0, Color(1.0, 0.08, 0.18, alpha))
		Role.BONE_ARCANIST:
			_draw_lane(right, 510.0, 16.0, Color(0.26, 0.62, 1.0, alpha * 0.72))
			draw_circle(_facing * 30.0, 10.0 + windup_ratio * 7.0, Color(0.42, 0.82, 1.0, 0.46))
		Role.WARCALLER:
			var sigil_radius := 42.0 + windup_ratio * 18.0
			draw_arc(Vector2.ZERO, sigil_radius, -PI * 0.85, PI * 0.85, 24, Color(0.48, 1.0, 0.52, 0.28 + windup_ratio * 0.18), 2.0, true)
			draw_line(Vector2(-11.0, 0.0), Vector2(11.0, 0.0), Color(0.65, 1.0, 0.62, 0.58), 3.0, true)
			draw_line(Vector2(0.0, -11.0), Vector2(0.0, 11.0), Color(0.65, 1.0, 0.62, 0.58), 3.0, true)
		Role.GRAVE_DEADEYE:
			_draw_lane(right, 590.0, 10.0, Color(0.78, 0.20, 0.98, alpha * 0.82))


func _draw_lane(right: Vector2, reach: float, half_width: float, color: Color) -> void:
	var corners := PackedVector2Array([
		right * half_width,
		_facing * reach + right * half_width,
		_facing * reach - right * half_width,
		-right * half_width,
	])
	draw_colored_polygon(corners, Color(color, color.a * 0.58))
	draw_polyline(corners + PackedVector2Array([corners[0]]), Color(color, minf(0.24, color.a * 1.65)), 1.25, true)


func _draw_bar(at: Vector2, width: float, ratio: float, color: Color) -> void:
	draw_rect(Rect2(at, Vector2(width, 4.0)), Color(0.02, 0.03, 0.04, 0.86))
	draw_rect(Rect2(at + Vector2.ONE, Vector2((width - 2.0) * clampf(ratio, 0.0, 1.0), 2.0)), color)