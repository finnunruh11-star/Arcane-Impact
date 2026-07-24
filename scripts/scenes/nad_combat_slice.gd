extends Node2D


var _world: Node2D
var _player: NadPlayer
var _impact_director: ImpactDirector
var _hud: NadCombatHud
var _enemies: Array[ReliquaryPursuer] = []
var _wave := 1
var _next_wave_timer := 0.0
var _restart_timer := 0.0


func _enter_tree() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	InputProfile.ensure_default_bindings()


func _ready() -> void:
	_world = Node2D.new()
	_world.name = "CombatWorld"
	_world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_world)

	var arena := ArenaBackdrop.new()
	arena.name = "ShatteredReliquary"
	_world.add_child(arena)

	_player = NadPlayer.new()
	_player.name = "Nad"
	_player.global_position = Vector2(330.0, 360.0)
	_world.add_child(_player)

	var camera := CameraTrauma.new()
	camera.name = "CameraTrauma"
	add_child(camera)
	var hit_stop := HitStop.new()
	hit_stop.name = "HitStop"
	add_child(hit_stop)
	_impact_director = ImpactDirector.new()
	_impact_director.name = "ImpactDirector"
	_impact_director.configure(camera, hit_stop)
	add_child(_impact_director)

	_hud = NadCombatHud.new()
	_hud.name = "NadCombatHud"
	_hud.configure(_player)
	add_child(_hud)

	_player.combat_impact.connect(_impact_director.nad_combat_impact)
	_player.effect_requested.connect(_impact_director.play_effect)
	_player.audio_requested.connect(_impact_director.play_audio)
	_player.mind_link_requested.connect(_impact_director.play_mind_link)
	_player.distortion_requested.connect(_impact_director.play_mental_distortion)
	_player.announcement_requested.connect(_hud.announce)
	_player.defeated.connect(_on_player_defeated)
	_spawn_wave()
	_hud.announce("THE MIND BENDS FIRST")
	print("Arcane Impact Nad content slice ready.")


func _process(delta: float) -> void:
	_enemies = _enemies.filter(func(enemy: ReliquaryPursuer) -> bool: return is_instance_valid(enemy) and enemy.is_alive())
	_hud.set_encounter(_wave, _enemies.size())
	if Input.is_action_just_pressed(&"toggle_debug"):
		_player.debug_draw_enabled = not _player.debug_draw_enabled
		_player.queue_redraw()
	if _next_wave_timer > 0.0:
		_next_wave_timer -= delta
		if _next_wave_timer <= 0.0 and _player.is_alive():
			_wave += 1
			_player.heal(28.0)
			_player.restore_mana(34.0)
			_spawn_wave()
	if _restart_timer > 0.0:
		_restart_timer -= delta
		if _restart_timer <= 0.0:
			get_tree().reload_current_scene()


func _spawn_wave() -> void:
	var spawn_points := [
		Vector2(930.0, 228.0),
		Vector2(1010.0, 488.0),
		Vector2(760.0, 520.0),
		Vector2(790.0, 194.0),
		Vector2(1110.0, 352.0),
	]
	var enemy_count := mini(5, 2 + _wave)
	for enemy_index: int in enemy_count:
		var enemy := ReliquaryPursuer.new()
		enemy.configure(_player, (enemy_index + _wave - 1) % 3)
		enemy.global_position = spawn_points[enemy_index]
		_world.add_child(enemy)
		enemy.attack_connected.connect(_impact_director.enemy_attack_impact)
		enemy.effect_requested.connect(_impact_director.play_effect)
		enemy.audio_requested.connect(_impact_director.play_audio)
		enemy.defeated.connect(_on_enemy_defeated)
		_enemies.append(enemy)
	_hud.set_encounter(_wave, _enemies.size())
	_hud.announce("WAVE %d" % _wave)


func _on_enemy_defeated(_enemy: ReliquaryPursuer) -> void:
	call_deferred(&"_check_wave_clear")


func _check_wave_clear() -> void:
	var alive_count := 0
	for enemy: ReliquaryPursuer in _enemies:
		if is_instance_valid(enemy) and enemy.is_alive():
			alive_count += 1
	if alive_count == 0 and _next_wave_timer <= 0.0:
		_next_wave_timer = 2.2
		_hud.announce("RELIQUARY SUBDUED")


func _on_player_defeated() -> void:
	_hud.announce("NAD'S CONDUIT BREAKS")
	_restart_timer = 2.6
