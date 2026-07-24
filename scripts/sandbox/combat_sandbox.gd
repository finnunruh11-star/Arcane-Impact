extends Node2D

var _world: Node2D
var _player: PrototypePlayer
var _dummy: TargetDummy
var _impact_director: ImpactDirector
var _hud: SandboxHud


func _enter_tree() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	InputProfile.ensure_default_bindings()


func _ready() -> void:
	_world = Node2D.new()
	_world.name = "CombatWorld"
	_world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_world)

	var arena := ArenaBackdrop.new()
	arena.name = "ShatteredReliquaryLab"
	_world.add_child(arena)

	_player = PrototypePlayer.new()
	_player.name = "PrototypePlayer"
	_player.global_position = Vector2(350.0, 360.0)
	_world.add_child(_player)

	_dummy = TargetDummy.new()
	_dummy.name = "TargetDummy"
	_dummy.global_position = Vector2(890.0, 360.0)
	_world.add_child(_dummy)

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

	_hud = SandboxHud.new()
	_hud.name = "SandboxHud"
	_hud.configure(_player, _dummy)
	add_child(_hud)

	_player.cast_committed.connect(_impact_director.cast_committed)
	_player.impact_landed.connect(_impact_director.heavy_impact)
	_dummy.impact_received.connect(_hud.show_impact)
	print("Arcane Impact combat sandbox ready.")


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed(&"interact") and is_instance_valid(_dummy):
		_dummy.reset_full()
	if Input.is_action_just_pressed(&"toggle_debug") and is_instance_valid(_player):
		_player.debug_draw_enabled = not _player.debug_draw_enabled
		_player.queue_redraw()