extends Node

# Emitted when the on-screen touch controls must be shown (true) or hidden (false)
signal touch_mode_changed(enabled: bool)

const INPUT_CARRY='carry_sheep'
const INPUT_ATTACK='player_attack'
const INPUT_JUMP='player_jump'
const INPUT_ACTION='player_action'

const INPUT_FOCUS_NEXT="ui_focus_next"

const INPUT_LEFT='ui_left'
const INPUT_RIGHT='ui_right'
const INPUT_UP='ui_up'
const INPUT_DOWN='ui_down'

# Controls of each profile, as in Beat and Match to Pass: "solo" (one player,
# on the actions of the project, its keys stay valid too), "p1" / "p2" (two
# players, actions "p1_..." / "p2_..."). Each profile plays on the keyboard or
# on a gamepad, keys and buttons can be changed (controls screen of the menu)
# and are saved. Keys are physical keys: same place on AZERTY and QWERTY.
enum Device { KEYBOARD, GAMEPAD }

const PATH_CONFIG := "user://controls.cfg"
const PLAYER_ACTIONS := [INPUT_LEFT, INPUT_RIGHT, INPUT_JUMP, INPUT_ATTACK, INPUT_ACTION]
const ACTION_LABELS := {
	INPUT_LEFT: "LEFT",
	INPUT_RIGHT: "RIGHT",
	INPUT_JUMP: "JUMP",
	INPUT_ATTACK: "SHOOT",
	INPUT_ACTION: "ACTION",
}
const PROFILES := ["solo", "p1", "p2"]
const PROFILE_PREFIX := {"solo": "", "p1": "p1_", "p2": "p2_"}
# Player 1 left hand, player 2 right hand
const DEFAULT_KEYS := {
	"solo": {INPUT_LEFT: KEY_LEFT, INPUT_RIGHT: KEY_RIGHT, INPUT_JUMP: KEY_SPACE, INPUT_ATTACK: KEY_ENTER, INPUT_ACTION: KEY_TAB},
	"p1": {INPUT_LEFT: KEY_A, INPUT_RIGHT: KEY_D, INPUT_JUMP: KEY_W, INPUT_ATTACK: KEY_F, INPUT_ACTION: KEY_G},
	"p2": {INPUT_LEFT: KEY_LEFT, INPUT_RIGHT: KEY_RIGHT, INPUT_JUMP: KEY_UP, INPUT_ATTACK: KEY_L, INPUT_ACTION: KEY_K},
}
# On a gamepad, moving stays on the d-pad and the left stick
const GAMEPAD_MOVE := {
	INPUT_LEFT: [JOY_BUTTON_DPAD_LEFT, JOY_AXIS_LEFT_X, -1.0],
	INPUT_RIGHT: [JOY_BUTTON_DPAD_RIGHT, JOY_AXIS_LEFT_X, 1.0],
}
const GAMEPAD_MOVE_LABEL := "STICK"
const GAMEPAD_REMAPPABLE := [INPUT_JUMP, INPUT_ATTACK, INPUT_ACTION]
const DEFAULT_BUTTONS := {INPUT_JUMP: JOY_BUTTON_A, INPUT_ATTACK: JOY_BUTTON_B, INPUT_ACTION: JOY_BUTTON_X}
# Moving and pause
const GAMEPAD_RESERVED := [JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_RIGHT, JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_DOWN,
	JOY_BUTTON_START, JOY_BUTTON_BACK, JOY_BUTTON_GUIDE]
const BUTTON_NAMES := {
	JOY_BUTTON_A: "A", JOY_BUTTON_B: "B", JOY_BUTTON_X: "X", JOY_BUTTON_Y: "Y",
	JOY_BUTTON_LEFT_SHOULDER: "LB", JOY_BUTTON_RIGHT_SHOULDER: "RB",
	JOY_BUTTON_LEFT_STICK: "L3", JOY_BUTTON_RIGHT_STICK: "R3",
}
const DEADZONE := 0.5
# Device id of no connected pad: unassigned pad events never fire
const NO_DEVICE := 99

var _touch_mode := false
var _two_players := false
# Events of the player actions as defined in the project (kept for "solo")
var _project_events := {}
# false while recording the promo (capture.gd): the user config is not overwritten
var save_enabled := true
# profile -> {"device": Device, "keys": {action: physical keycode}, "buttons": {action: button}}
var profiles := {}

func _ready() -> void:
	# Keep listening while the game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	for action in PLAYER_ACTIONS:
		_project_events[action] = InputMap.action_get_events(action).map(func(event): return event.duplicate())
	reset_profiles()
	load_config()
	apply()
	Input.joy_connection_changed.connect(func(_device, _connected): apply())
	# Touch controls by default on phones/tablets, the first key or pad button hides them
	_touch_mode = OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios") \
		or DisplayServer.is_touchscreen_available()

func _input(event: InputEvent) -> void:
	# Touch events emulated from the mouse (emulate_touch_from_mouse) don't count
	if event is InputEventScreenTouch and event.pressed and event.device != InputEvent.DEVICE_ID_EMULATION:
		set_touch_mode(true)
	elif (event is InputEventKey or event is InputEventJoypadButton) and event.pressed:
		set_touch_mode(false)

#touch controls
func is_touch_mode() -> bool:
	return _touch_mode

func set_touch_mode(enabled: bool) -> void:
	if enabled == _touch_mode:
		return
	_touch_mode = enabled
	touch_mode_changed.emit(enabled)

#two players: the game reads the "p1_" / "p2_" actions
func is_two_players() -> bool:
	return _two_players

func set_two_players(enabled: bool) -> void:
	_two_players = enabled

func get_action_name(action: String, player := 1) -> String:
	if !_two_players:
		return action
	return PROFILE_PREFIX["p2" if player == 2 else "p1"] + action

func profile_for(player: int, two_players: bool) -> String:
	if !two_players:
		return "solo"
	return "p2" if player == 2 else "p1"


func reset_profiles() -> void:
	var pads := Input.get_connected_joypads().size()
	for profile in PROFILES:
		profiles[profile] = {
			"device": Device.KEYBOARD,
			"keys": DEFAULT_KEYS[profile].duplicate(),
			"buttons": DEFAULT_BUTTONS.duplicate(),
		}
	# A gamepad is there: player 2 takes it
	if pads > 0:
		profiles["p2"]["device"] = Device.GAMEPAD

func is_keyboard(profile: String) -> bool:
	return profiles[profile]["device"] == Device.KEYBOARD

func set_device(profile: String, device: int) -> void:
	profiles[profile]["device"] = device
	apply()

func set_key(profile: String, action: String, keycode: int) -> void:
	profiles[profile]["keys"][action] = keycode
	apply()

func set_button(profile: String, action: String, button: int) -> void:
	profiles[profile]["buttons"][action] = button
	apply()

func is_remappable(profile: String, action: String) -> bool:
	return is_keyboard(profile) or GAMEPAD_REMAPPABLE.has(action)

# Gamepad of a profile: the connected pads, in order, to the gamepad players
func gamepad_for(profile: String) -> int:
	var pads := Input.get_connected_joypads()
	var rank := 0
	if profile == "p2" and !is_keyboard("p1"):
		rank = 1
	if is_keyboard(profile) or rank >= pads.size():
		return -1
	return pads[rank]

func gamepad_name(profile: String) -> String:
	var pad := gamepad_for(profile)
	if pad < 0:
		return ""
	return Input.get_joy_name(pad).to_upper()

# Physical key from a key event (the layout key when there is no physical one)
func keycode_from_event(event: InputEventKey) -> int:
	return event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode

# Gamepad button for the remapping, -1 when the event does not fit
func button_from_event(event: InputEvent) -> int:
	if event is InputEventJoypadButton and event.pressed and not GAMEPAD_RESERVED.has(event.button_index):
		return event.button_index
	return -1

func key_label(keycode: int) -> String:
	var local := DisplayServer.keyboard_get_keycode_from_physical(keycode)
	return OS.get_keycode_string(local if local != KEY_NONE else keycode).to_upper()

func button_label(button: int) -> String:
	return BUTTON_NAMES.get(button, "BUTTON %d" % button)

func action_label(profile: String, action: String) -> String:
	if is_keyboard(profile):
		return key_label(profiles[profile]["keys"][action])
	if GAMEPAD_REMAPPABLE.has(action):
		return button_label(profiles[profile]["buttons"][action])
	return GAMEPAD_MOVE_LABEL

func profiles_of(two_players: bool) -> Array:
	return ["p1", "p2"] if two_players else ["solo"]

# Keys used twice by the keyboard players of the mode
func conflicting_keys(two_players: bool) -> Array:
	var seen := {}
	var conflicts := []
	for profile in profiles_of(two_players):
		if !is_keyboard(profile):
			continue
		for action in PLAYER_ACTIONS:
			var keycode: int = profiles[profile]["keys"][action]
			if seen.has(keycode):
				conflicts.append(keycode)
			seen[keycode] = true
	return conflicts

# Actions sharing a button on the gamepad of a profile
func conflicting_buttons(profile: String) -> Array:
	var conflicts := []
	if is_keyboard(profile):
		return conflicts
	var buttons: Dictionary = profiles[profile]["buttons"]
	for action in GAMEPAD_REMAPPABLE:
		for other in GAMEPAD_REMAPPABLE:
			if other != action and buttons[other] == buttons[action] and not conflicts.has(action):
				conflicts.append(action)
	return conflicts

# "" when the controls of the mode can be played, else the message to show
func validation_error(two_players: bool) -> String:
	for profile in profiles_of(two_players):
		if !is_keyboard(profile) and gamepad_for(profile) < 0:
			return "PLUG A GAMEPAD" if profile == "solo" else "PLUG A GAMEPAD FOR PLAYER %s" % profile.substr(1)
	if !conflicting_keys(two_players).is_empty():
		return "SAME KEY USED TWICE"
	for profile in profiles_of(two_players):
		if !conflicting_buttons(profile).is_empty():
			return "SAME BUTTON USED TWICE"
	return ""


# Profiles to the InputMap
func apply() -> void:
	for profile in PROFILES:
		var configured := _profile_events(profile)
		for action in PLAYER_ACTIONS:
			var name: String = PROFILE_PREFIX[profile] + action
			if !InputMap.has_action(name):
				InputMap.add_action(name, DEADZONE)
			InputMap.action_erase_events(name)
			for event in configured[action]:
				InputMap.action_add_event(name, event)
		if profile == "solo":
			_add_project_events(configured)

func _profile_events(profile: String) -> Dictionary:
	var events := {}
	var pad := gamepad_for(profile)
	for action in PLAYER_ACTIONS:
		events[action] = []
		if is_keyboard(profile):
			var key := InputEventKey.new()
			key.physical_keycode = profiles[profile]["keys"][action]
			events[action].append(key)
			continue
		var device := pad if pad >= 0 else NO_DEVICE
		if GAMEPAD_MOVE.has(action):
			var button := InputEventJoypadButton.new()
			button.device = device
			button.button_index = GAMEPAD_MOVE[action][0]
			events[action].append(button)
			var motion := InputEventJoypadMotion.new()
			motion.device = device
			motion.axis = GAMEPAD_MOVE[action][1]
			motion.axis_value = GAMEPAD_MOVE[action][2]
			events[action].append(motion)
		else:
			var button := InputEventJoypadButton.new()
			button.device = device
			button.button_index = profiles[profile]["buttons"][action]
			events[action].append(button)
	return events

# One player: the keys and buttons of the project stay valid (touch controls,
# menus, any gamepad), except the ones now used by another action
func _add_project_events(configured: Dictionary) -> void:
	for action in PLAYER_ACTIONS:
		for event in _project_events[action]:
			var taken := false
			for other in PLAYER_ACTIONS:
				for existing in configured[other]:
					if _same_input(event, existing):
						taken = true
			if !taken:
				InputMap.action_add_event(action, event.duplicate())

static func _same_input(a: InputEvent, b: InputEvent) -> bool:
	if a is InputEventKey and b is InputEventKey:
		var key_a: int = a.physical_keycode if a.physical_keycode != KEY_NONE else a.keycode
		var key_b: int = b.physical_keycode if b.physical_keycode != KEY_NONE else b.keycode
		return key_a == key_b
	if a is InputEventJoypadButton and b is InputEventJoypadButton:
		return a.button_index == b.button_index
	if a is InputEventJoypadMotion and b is InputEventJoypadMotion:
		return a.axis == b.axis and signf(a.axis_value) == signf(b.axis_value)
	return false


func save_config() -> void:
	if !save_enabled:
		return
	var config := ConfigFile.new()
	for profile in PROFILES:
		config.set_value(profile, "device", profiles[profile]["device"])
		config.set_value(profile, "keys", profiles[profile]["keys"])
		config.set_value(profile, "buttons", profiles[profile]["buttons"])
	config.save(PATH_CONFIG)

func load_config() -> void:
	var config := ConfigFile.new()
	if config.load(PATH_CONFIG) != OK:
		return
	for profile in PROFILES:
		var device = config.get_value(profile, "device", profiles[profile]["device"])
		if device in [Device.KEYBOARD, Device.GAMEPAD]:
			profiles[profile]["device"] = device
		var keys = config.get_value(profile, "keys", {})
		if keys is Dictionary:
			for action in PLAYER_ACTIONS:
				if keys.has(action) and typeof(keys[action]) == TYPE_INT:
					profiles[profile]["keys"][action] = keys[action]
		var buttons = config.get_value(profile, "buttons", {})
		if buttons is Dictionary:
			for action in GAMEPAD_REMAPPABLE:
				if buttons.has(action) and typeof(buttons[action]) == TYPE_INT:
					profiles[profile]["buttons"][action] = buttons[action]


func press_jump_button(player := 1)->void:
	Input.action_press(get_action_name(INPUT_JUMP, player))

func is_press_jump_button(player := 1)->bool:
	return _is_button_pressed_in_list([get_action_name(INPUT_JUMP, player)])


func press_action_button(player := 1)->void:
	Input.action_press(get_action_name(INPUT_ACTION, player))

func is_press_action_button(player := 1)->bool:
	return _is_button_pressed_in_list([get_action_name(INPUT_ACTION, player)])


func press_carry_button()->void:
	Input.action_press(INPUT_CARRY)

func is_press_carry_button()->bool:
	return _is_button_pressed_in_list([INPUT_CARRY])


func press_attack_button(player := 1)->void:
	Input.action_press(get_action_name(INPUT_ATTACK, player))

func is_press_attack_button(player := 1)->bool:
	return _is_button_pressed_in_list([get_action_name(INPUT_ATTACK, player)])
	

#direction
func get_direction(player := 1)->float:
	return Input.get_axis(get_action_name(INPUT_LEFT, player), get_action_name(INPUT_RIGHT, player))
	
func press_left_button()->void:
	return Input.action_press(INPUT_LEFT)

func is_press_left_button()->bool:
	return Input.is_action_just_pressed(INPUT_LEFT)

func press_right_button()->void:
	return Input.action_press(INPUT_RIGHT)

func is_press_right_button()->bool:
	return Input.is_action_just_pressed(INPUT_RIGHT)

func press_up_button()->void:
	return Input.action_press(INPUT_UP)

func is_press_up_button()->bool:
	return Input.is_action_just_pressed(INPUT_UP)

func press_down_button()->void:
	return Input.action_press(INPUT_DOWN)

func is_press_down_button()->bool:
	return Input.is_action_just_pressed(INPUT_DOWN)



func is_press_next_button()->bool:
	return _is_button_pressed_in_list([INPUT_FOCUS_NEXT,INPUT_ACTION,INPUT_JUMP,INPUT_UP,INPUT_DOWN])
	
func is_press_validate_button()->bool:
	return _is_button_pressed_in_list([INPUT_ATTACK])

func reset_move(player := 1)->void:
	for valueLoop in [INPUT_RIGHT,INPUT_LEFT,INPUT_UP,INPUT_DOWN]:
		var action := get_action_name(valueLoop, player)
		if InputMap.has_action(action):
			Input.action_release(action)

func _is_button_pressed_in_list(valueList: Array)->bool:
	for valueLoop in valueList:
		if Input.is_action_just_pressed(valueLoop):
			return true
	return false
