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

var _touch_mode := false

func _ready() -> void:
	# Keep listening while the game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
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

func press_jump_button()->void:
	Input.action_press(INPUT_JUMP)

func is_press_jump_button()->bool:
	return _is_button_pressed_in_list([INPUT_JUMP])


func press_action_button()->void:
	Input.action_press(INPUT_ACTION)

func is_press_action_button()->bool:
	return _is_button_pressed_in_list([INPUT_ACTION])


func press_carry_button()->void:
	Input.action_press(INPUT_CARRY)

func is_press_carry_button()->bool:
	return _is_button_pressed_in_list([INPUT_CARRY])


func press_attack_button()->void:
	Input.action_press(INPUT_ATTACK)

func is_press_attack_button()->bool:
	return _is_button_pressed_in_list([INPUT_ATTACK])
	

#direction
func get_direction()->float:
	return Input.get_axis(INPUT_LEFT, INPUT_RIGHT)
	
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

func reset_move()->void:
	for valueLoop in [INPUT_RIGHT,INPUT_LEFT,INPUT_UP,INPUT_DOWN]:
		Input.action_release(valueLoop)

func _is_button_pressed_in_list(valueList: Array)->bool:
	for valueLoop in valueList:
		if Input.is_action_just_pressed(valueLoop):
			return true
	return false
