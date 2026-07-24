class_name InputProfile
extends RefCounted


const REQUIRED_ACTIONS: Array[StringName] = [
	&"move_left",
	&"move_right",
	&"move_up",
	&"move_down",
	&"primary",
	&"signature",
	&"ability_1",
	&"ability_2",
	&"evade",
	&"ultimate",
	&"interact",
	&"target_lock",
	&"pause",
	&"toggle_debug",
]


static func ensure_default_bindings() -> void:
	if InputMap.has_action(&"move_left"):
		return

	_ensure_action(&"move_left", 0.18)
	_add_key(&"move_left", KEY_A)
	_add_joy_axis(&"move_left", JOY_AXIS_LEFT_X, -1.0)

	_ensure_action(&"move_right", 0.18)
	_add_key(&"move_right", KEY_D)
	_add_joy_axis(&"move_right", JOY_AXIS_LEFT_X, 1.0)

	_ensure_action(&"move_up", 0.18)
	_add_key(&"move_up", KEY_W)
	_add_joy_axis(&"move_up", JOY_AXIS_LEFT_Y, -1.0)

	_ensure_action(&"move_down", 0.18)
	_add_key(&"move_down", KEY_S)
	_add_joy_axis(&"move_down", JOY_AXIS_LEFT_Y, 1.0)

	_ensure_action(&"primary", 0.35)
	_add_mouse_button(&"primary", MOUSE_BUTTON_LEFT)
	_add_joy_axis(&"primary", JOY_AXIS_TRIGGER_RIGHT, 1.0)

	_ensure_action(&"signature", 0.35)
	_add_mouse_button(&"signature", MOUSE_BUTTON_RIGHT)
	_add_joy_axis(&"signature", JOY_AXIS_TRIGGER_LEFT, 1.0)

	_ensure_action(&"ability_1", 0.20)
	_add_key(&"ability_1", KEY_Q)
	_add_joy_button(&"ability_1", JOY_BUTTON_RIGHT_SHOULDER)

	_ensure_action(&"ability_2", 0.20)
	_add_key(&"ability_2", KEY_E)
	_add_joy_button(&"ability_2", JOY_BUTTON_LEFT_SHOULDER)

	_ensure_action(&"evade", 0.20)
	_add_key(&"evade", KEY_SPACE)
	_add_joy_button(&"evade", JOY_BUTTON_A)

	_ensure_action(&"ultimate", 0.20)
	_add_key(&"ultimate", KEY_R)
	_add_joy_button(&"ultimate", JOY_BUTTON_Y)

	_ensure_action(&"interact", 0.20)
	_add_key(&"interact", KEY_F)
	_add_joy_button(&"interact", JOY_BUTTON_X)

	_ensure_action(&"target_lock", 0.20)
	_add_mouse_button(&"target_lock", MOUSE_BUTTON_MIDDLE)
	_add_joy_button(&"target_lock", JOY_BUTTON_RIGHT_STICK)

	_ensure_action(&"pause", 0.20)
	_add_key(&"pause", KEY_ESCAPE)
	_add_joy_button(&"pause", JOY_BUTTON_START)
	_add_joy_button(&"pause", JOY_BUTTON_B)

	_ensure_action(&"toggle_debug", 0.20)
	_add_key(&"toggle_debug", KEY_TAB)
	_add_joy_button(&"toggle_debug", JOY_BUTTON_DPAD_UP)


static func has_complete_action_set() -> bool:
	for action: StringName in REQUIRED_ACTIONS:
		if not InputMap.has_action(action) or InputMap.action_get_events(action).is_empty():
			return false
	return true


static func _ensure_action(action: StringName, deadzone: float) -> void:
	InputMap.add_action(action, deadzone)


static func _add_key(action: StringName, keycode: int) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	InputMap.action_add_event(action, event)


static func _add_mouse_button(action: StringName, button: int) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button
	InputMap.action_add_event(action, event)


static func _add_joy_button(action: StringName, button: int) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	InputMap.action_add_event(action, event)


static func _add_joy_axis(action: StringName, axis: int, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	InputMap.action_add_event(action, event)