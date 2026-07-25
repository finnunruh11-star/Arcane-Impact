class_name TrainingRun
extends Node2D


const ProgressionScript := preload("res://scripts/survivors/survivor_progression.gd")
const TrainingHudScript := preload("res://scripts/ui/training_hud.gd")
const TRAINING_HERO_SETTING := "arcane_impact/training_hero_index"
const HERO_SCRIPTS := [
	preload("res://scripts/characters/kat/kat_player.gd"),
	preload("res://scripts/characters/sniff/sniff_player.gd"),
	preload("res://scripts/characters/nad/nad_player.gd"),
	preload("res://scripts/characters/fin/fin_player.gd"),
]
const HUD_SCRIPTS := [
	preload("res://scripts/ui/kat_combat_hud.gd"),
	preload("res://scripts/ui/sniff_combat_hud.gd"),
	preload("res://scripts/ui/nad_combat_hud.gd"),
	preload("res://scripts/ui/fin_combat_hud.gd"),
]
const HERO_NAMES := ["Kat", "Sniff", "Nad", "Fin"]
const HERO_ACCENTS := [Color("cf5268"), Color("42d7ed"), Color("78d6a6"), Color("dfbd58")]
const DUMMY_POSITIONS := [
	Vector2(720.0, 360.0),
	Vector2(900.0, 205.0),
	Vector2(900.0, 515.0),
	Vector2(1080.0, 290.0),
	Vector2(1080.0, 430.0),
]

@export_range(0, 3, 1) var hero_index := 0
@export var audio_enabled := true

var _world: Node2D
var _player: Node2D
var _dummies: Array[TargetDummy] = []
var _progression
var _impact_director: ImpactDirector
var _hero_hud: CanvasLayer
var _training_hud: CanvasLayer
var _level := 1


func _enter_tree() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	InputProfile.ensure_default_bindings()


func _ready() -> void:
	hero_index = clampi(int(ProjectSettings.get_setting(TRAINING_HERO_SETTING, hero_index)), 0, HERO_SCRIPTS.size() - 1)
	_build_world()
	_build_presentation()
	_build_player()
	_build_dummies()
	_build_huds()
	set_training_level(1)
	print("Arcane Impact training ready for %s." % HERO_NAMES[hero_index])


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed(&"pause"):
		_return_to_roster()
	elif Input.is_action_just_pressed(&"interact"):
		reset_dummies()
	elif Input.is_action_just_pressed(&"toggle_debug"):
		_player.set(&"debug_draw_enabled", not bool(_player.get(&"debug_draw_enabled")))
		_player.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	var key := (event as InputEventKey).physical_keycode
	if key == KEY_PAGEUP:
		set_training_level(_level + 1)
	elif key == KEY_PAGEDOWN:
		set_training_level(_level - 1)


func get_player() -> Node2D:
	return _player


func get_dummies() -> Array[TargetDummy]:
	return _dummies


func get_training_level() -> int:
	return _level


func set_training_level(level: int) -> void:
	_level = clampi(level, 1, 20)
	_progression.configure(hero_index)
	_progression.set_run_level(_level)
	for slot: StringName in SurvivorProgression.ABILITY_SLOTS:
		_progression.apply_pick(slot, _level)
	_player.call(&"set_survivor_basic_attack_progress", _progression.get_basic_attack_tier(), _progression.get_basic_attack_power_multiplier())
	for slot: StringName in SurvivorProgression.ABILITY_SLOTS:
		_player.call(&"set_survivor_ability_progress", slot, _progression.get_rank(slot), _progression.get_ability_tier(slot), _progression.get_ability_power_multiplier(slot), _progression.get_ability_cooldown_multiplier(slot))
	_hero_hud.call(&"set_survivor_encounter", _level, _dummies.size())
	_training_hud.set_level(_level)


func reset_dummies() -> void:
	for dummy: TargetDummy in _dummies:
		if is_instance_valid(dummy):
			dummy.reset_full()


func _build_world() -> void:
	_world = Node2D.new()
	_world.name = "CombatWorld"
	_world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_world)
	var arena := ArenaBackdrop.new()
	arena.name = "ShatteredReliquaryLab"
	_world.add_child(arena)


func _build_presentation() -> void:
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


func _build_player() -> void:
	_progression = ProgressionScript.new()
	var player_script: Script = HERO_SCRIPTS[hero_index]
	_player = player_script.new() as Node2D
	_player.name = HERO_NAMES[hero_index]
	_player.global_position = Vector2(330.0, 360.0)
	_player.call(&"set_survivor_mode", true)
	_player.call(&"set_survivor_power_multiplier", 1.0)
	if _player.has_method(&"set_movement_bounds"):
		_player.call(&"set_movement_bounds", ArenaBackdrop.PLAYABLE_RECT.grow(-36.0))
	_world.add_child(_player)
	_player.connect(&"effect_requested", Callable(_impact_director, &"play_effect"))
	if audio_enabled:
		_player.connect(&"audio_requested", Callable(_impact_director, &"play_audio"))
	match hero_index:
		0:
			_player.connect(&"combat_impact", Callable(_impact_director, &"kat_combat_impact"))
			_player.connect(&"guard_impact", Callable(_impact_director, &"play_guard_impact"))
		1:
			_player.connect(&"combat_impact", Callable(_impact_director, &"sniff_combat_impact"))
			_player.connect(&"lightning_arc_requested", Callable(_impact_director, &"play_lightning_arc"))
			_player.connect(&"thunder_burst_requested", Callable(_impact_director, &"play_thunder_burst"))
		2:
			_player.connect(&"combat_impact", Callable(_impact_director, &"nad_combat_impact"))
			_player.connect(&"mind_link_requested", Callable(_impact_director, &"play_mind_link"))
			_player.connect(&"distortion_requested", Callable(_impact_director, &"play_mental_distortion"))
		3:
			_player.connect(&"combat_impact", Callable(_impact_director, &"fin_combat_impact"))


func _build_dummies() -> void:
	for index: int in DUMMY_POSITIONS.size():
		var dummy := TargetDummy.new()
		dummy.name = "TargetDummy%d" % (index + 1)
		dummy.global_position = DUMMY_POSITIONS[index]
		dummy.add_to_group(&"enemies")
		_world.add_child(dummy)
		_dummies.append(dummy)


func _build_huds() -> void:
	var hud_script: Script = HUD_SCRIPTS[hero_index]
	_hero_hud = hud_script.new() as CanvasLayer
	_hero_hud.call(&"configure", _player)
	add_child(_hero_hud)
	_player.connect(&"announcement_requested", Callable(_hero_hud, &"announce"))
	_training_hud = TrainingHudScript.new() as CanvasLayer
	_training_hud.configure(HERO_NAMES[hero_index], HERO_ACCENTS[hero_index])
	_training_hud.level_requested.connect(_on_level_requested)
	_training_hud.reset_requested.connect(reset_dummies)
	_training_hud.roster_requested.connect(_return_to_roster)
	add_child(_training_hud)


func _on_level_requested(requested_level: int) -> void:
	if requested_level == -1:
		set_training_level(_level - 1)
	elif requested_level == -2:
		set_training_level(_level + 1)
	else:
		set_training_level(requested_level)


func _return_to_roster() -> void:
	get_tree().change_scene_to_file("res://scenes/roster_select.tscn")