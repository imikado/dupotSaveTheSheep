extends CanvasLayer
class_name ControlsScreen

## Shown by the menu after 1 PLAYER / 2 PLAYERS, as the coop setup of Beat and
## Match to Pass: each player picks keyboard or gamepad and changes his keys /
## buttons, then tries them with his Gordon in the test area (TEST).
## Up / down: row, left / right: player (or button), Enter: change,
## Esc: back (or stop the test / cancel the new key).

signal start_pressed
signal back_pressed

const FONT = preload("res://src/UI/Controls/Shared/Pixeled.ttf")
const PLAYER_SCENES = {
	1: preload("res://src/Actors/Players/Player.tscn"),
	2: preload("res://src/Actors/Players/Player2.tscn"),
}

const COLOR_TITLE := Color(1, 0.839216, 0.360784)
const COLOR_SELECTED := Color(1, 0.839216, 0.360784)
const COLOR_NORMAL := Color(1, 1, 1, 0.9)
const COLOR_DIM := Color(1, 1, 1, 0.45)
const COLOR_ERROR := Color("ff4d4d")
const COLOR_HIGHLIGHT := Color(1.0, 0.83, 0.3, 0.22)
const COLOR_PANEL := Color(0.05, 0.05, 0.16, 0.94)
const COLOR_TEST_AREA := Color(0.0, 0.0, 0.05, 0.6)
const COLOR_GROUND := Color(0.36, 0.33, 0.45)

const SCREEN := Vector2(480, 270)
const ROW_HEIGHT := 12.0
const HIGHLIGHT_OFFSET_Y := 4.0
const ROW_DEVICE := 0
const ROW_FIRST_KEY := 1
const ROW_BUTTONS := ROW_FIRST_KEY + 5
const BUTTON_TEST := 0
const BUTTON_START := 1
const BUTTON_BACK := 2
const BUTTON_TEXTS := ["TEST", "START", "BACK"]
const BUTTON_X := [130.0, 205.0, 280.0]
const BUTTON_WIDTH := 70.0

const COLUMNS_SOLO := [150.0]
const COLUMNS_TWO := [28.0, 252.0]
const COLUMN_WIDTH_SOLO := 180.0
const COLUMN_WIDTH_TWO := 200.0
const NAME_WIDTH := 70.0

const Y_TITLE := 3.0
const Y_HEADER := 25.0
const Y_DEVICE := 37.0
const Y_FIRST_KEY := 49.0
const Y_PAD_NAME := 110.0
const Y_MESSAGE := 122.0
const TEST_AREA := Rect2(10, 136, 460, 100)
const GROUND_Y := 228.0
const Y_BUTTONS := 245.0
const PLAYER_START_X := {1: 190.0, 2: 290.0}

var _two_players := false
var _profiles: Array = []
var _columns: Array = []
var _column_width := 0.0
var _row := ROW_DEVICE
var _col := 0
var _capturing := false
var _testing := false
var _leaving := false

var _root: Control
var _highlight: ColorRect
# [column] -> {row: Label}
var _values: Array = []
var _names: Array = []
var _pad_labels: Array = []
var _message: Label
var _buttons: Array = []
var _font: FontVariation
var _message_tween: Tween
var _test_players: Array[Player] = []
var _test_hint: Label


func _init(two_players := false):
	_two_players = two_players
	layer = 20


func _ready():
	_profiles = GlobalInput.profiles_of(_two_players)
	_columns = COLUMNS_TWO if _two_players else COLUMNS_SOLO
	_column_width = COLUMN_WIDTH_TWO if _two_players else COLUMN_WIDTH_SOLO
	_font = FontVariation.new()
	_font.base_font = FONT
	_font.spacing_top = -6
	_font.spacing_bottom = -3
	# The menu buttons behind must not react to the keys of this screen
	get_viewport().gui_release_focus()
	_build_ui()
	_build_test_area()
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	refresh()


func _on_joy_connection_changed(_device: int, _connected: bool):
	GlobalInput.apply()
	refresh()


func _label(text: String, position: Vector2, width: float, alignment := HORIZONTAL_ALIGNMENT_LEFT, font_size := 8) -> Label:
	var label = Label.new()
	label.text = text
	label.add_theme_font_override("font", _font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", COLOR_NORMAL)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 3)
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = position
	label.size = Vector2(width, ROW_HEIGHT)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(label)
	return label


# Click / touch: selects the row then changes it
func _clickable(label: Label, row: int, col: int):
	label.mouse_filter = Control.MOUSE_FILTER_STOP
	label.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and !_capturing and !_leaving:
			_row = row
			_col = col
			activate()
	)


func _build_ui():
	_root = Control.new()
	_root.size = SCREEN
	add_child(_root)

	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0.04, 0.5)
	dim.size = SCREEN
	_root.add_child(dim)
	var panel = ColorRect.new()
	panel.color = COLOR_PANEL
	panel.position = Vector2(4, 2)
	panel.size = SCREEN - Vector2(8, 4)
	_root.add_child(panel)

	_highlight = ColorRect.new()
	_highlight.color = COLOR_HIGHLIGHT
	_highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_highlight)

	var title = _label("2 PLAYERS" if _two_players else "1 PLAYER", Vector2(0, Y_TITLE), SCREEN.x, HORIZONTAL_ALIGNMENT_CENTER, 16)
	title.size.y = 20
	title.add_theme_color_override("font_color", COLOR_TITLE)

	for col in _profiles.size():
		var x: float = _columns[col]
		_values.append({})
		_names.append({})
		if _two_players:
			var header = _label("PLAYER %d" % (col + 1), Vector2(x, Y_HEADER), _column_width, HORIZONTAL_ALIGNMENT_CENTER)
			header.add_theme_color_override("font_color", Player.COOP_COLORS[col + 1])

		_names[col][ROW_DEVICE] = _label("CONTROL", Vector2(x + 4, Y_DEVICE), NAME_WIDTH)
		_values[col][ROW_DEVICE] = _label("", Vector2(x + NAME_WIDTH, Y_DEVICE), _column_width - NAME_WIDTH - 4, HORIZONTAL_ALIGNMENT_RIGHT)
		_clickable(_values[col][ROW_DEVICE], ROW_DEVICE, col)

		for i in GlobalInput.PLAYER_ACTIONS.size():
			var row := ROW_FIRST_KEY + i
			var y := Y_FIRST_KEY + ROW_HEIGHT * i
			_names[col][row] = _label(GlobalInput.ACTION_LABELS[GlobalInput.PLAYER_ACTIONS[i]], Vector2(x + 4, y), NAME_WIDTH)
			_values[col][row] = _label("", Vector2(x + NAME_WIDTH, y), _column_width - NAME_WIDTH - 4, HORIZONTAL_ALIGNMENT_RIGHT)
			_clickable(_values[col][row], row, col)

		var pad = _label("", Vector2(x, Y_PAD_NAME), _column_width, HORIZONTAL_ALIGNMENT_CENTER)
		pad.clip_text = true
		_pad_labels.append(pad)

	_message = _label("", Vector2(0, Y_MESSAGE), SCREEN.x, HORIZONTAL_ALIGNMENT_CENTER)
	for i in BUTTON_TEXTS.size():
		var button = _label(BUTTON_TEXTS[i], Vector2(BUTTON_X[i], Y_BUTTONS), BUTTON_WIDTH, HORIZONTAL_ALIGNMENT_CENTER)
		_clickable(button, ROW_BUTTONS, i)
		_buttons.append(button)


# Ground, walls and the Gordon of each player, frozen until TEST
func _build_test_area():
	var area = ColorRect.new()
	area.color = COLOR_TEST_AREA
	area.position = TEST_AREA.position
	area.size = TEST_AREA.size
	area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(area)
	var ground_line = ColorRect.new()
	ground_line.color = COLOR_GROUND
	ground_line.position = Vector2(TEST_AREA.position.x, GROUND_Y)
	ground_line.size = Vector2(TEST_AREA.size.x, TEST_AREA.end.y - GROUND_Y)
	ground_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(ground_line)
	_test_hint = _label("TEST: TRY THE CONTROLS HERE", Vector2(TEST_AREA.position.x, TEST_AREA.position.y + 4), TEST_AREA.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	_test_hint.add_theme_color_override("font_color", COLOR_DIM)

	var world = Node2D.new()
	add_child(world)
	_add_wall(world, Vector2(TEST_AREA.get_center().x, GROUND_Y + 20), Vector2(TEST_AREA.size.x, 40))
	_add_wall(world, Vector2(TEST_AREA.position.x - 10, GROUND_Y - 100), Vector2(20, 240))
	_add_wall(world, Vector2(TEST_AREA.end.x + 10, GROUND_Y - 100), Vector2(20, 240))

	for col in _profiles.size():
		var index: int = col + 1
		var player: Player = PLAYER_SCENES[index].instantiate()
		player.player_index = index
		world.add_child(player)
		player.global_position = Vector2(PLAYER_START_X[index], GROUND_Y)
		player.set_physics_process(false)
		_test_players.append(player)
	if _test_players.size() == 2:
		_test_players[0].add_collision_exception_with(_test_players[1])
		_test_players[1].add_collision_exception_with(_test_players[0])


func _add_wall(parent: Node, center: Vector2, size: Vector2):
	var body = StaticBody2D.new()
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	body.add_child(shape)
	parent.add_child(body)
	body.global_position = center


func _process(_delta):
	if _testing:
		# Shooting as much as wanted
		GlobalPlayer.set_water(GlobalPlayer.MAX_WATER)


func set_testing(enabled: bool):
	_capturing = false
	_testing = enabled
	_test_hint.visible = !enabled
	for player in _test_players:
		player.set_physics_process(enabled)
		if !enabled:
			player.velocity = Vector2.ZERO
	for col in _profiles.size():
		GlobalInput.reset_move(col + 1)
	refresh()


func _profile(col: int) -> String:
	return _profiles[col]


# Rows of the selected player (on a gamepad, moving cannot be changed)
func selectable_rows() -> Array:
	var profile := _profile(0 if _row == ROW_BUTTONS else _col)
	var rows := [ROW_DEVICE]
	for i in GlobalInput.PLAYER_ACTIONS.size():
		if GlobalInput.is_remappable(profile, GlobalInput.PLAYER_ACTIONS[i]):
			rows.append(ROW_FIRST_KEY + i)
	rows.append(ROW_BUTTONS)
	return rows


func refresh():
	var conflicts := GlobalInput.conflicting_keys(_two_players)
	for col in _profiles.size():
		var profile := _profile(col)
		var keyboard := GlobalInput.is_keyboard(profile)
		var button_conflicts := GlobalInput.conflicting_buttons(profile)
		_values[col][ROW_DEVICE].text = "< KEYBOARD >" if keyboard else "< GAMEPAD >"
		_set_color(_values[col][ROW_DEVICE], _is_selected(ROW_DEVICE, col))

		for i in GlobalInput.PLAYER_ACTIONS.size():
			var row := ROW_FIRST_KEY + i
			var action: String = GlobalInput.PLAYER_ACTIONS[i]
			var label: Label = _values[col][row]
			var selected := _is_selected(row, col)
			if selected and _capturing:
				label.text = "PRESS A KEY" if keyboard else "PRESS A BUTTON"
			else:
				label.text = GlobalInput.action_label(profile, action)
			var editable := GlobalInput.is_remappable(profile, action)
			var error: bool = conflicts.has(GlobalInput.profiles[profile]["keys"][action]) if keyboard else button_conflicts.has(action)
			_set_color(label, selected, COLOR_ERROR if error else (COLOR_NORMAL if editable else COLOR_DIM))
			_names[col][row].add_theme_color_override("font_color", COLOR_NORMAL if editable else COLOR_DIM)

		if keyboard:
			_pad_labels[col].text = ""
		else:
			var pad_name: String = GlobalInput.gamepad_name(profile)
			_pad_labels[col].text = pad_name if pad_name != "" else "NO GAMEPAD"
			_pad_labels[col].add_theme_color_override("font_color", COLOR_DIM if pad_name != "" else COLOR_ERROR)

	var error_text := GlobalInput.validation_error(_two_players)
	if _capturing:
		var keyboard := GlobalInput.is_keyboard(_profile(_col))
		_message.text = "PRESS A KEY  -  ESC: CANCEL" if keyboard else "PRESS A BUTTON  -  START: CANCEL"
		_message.add_theme_color_override("font_color", COLOR_SELECTED)
	elif _testing:
		_message.text = "TRY THE CONTROLS  -  ESC: STOP THE TEST"
		_message.add_theme_color_override("font_color", COLOR_SELECTED)
	elif error_text != "":
		_message.text = error_text
		_message.add_theme_color_override("font_color", COLOR_ERROR)
	else:
		_message.text = "ENTER: CHANGE   ESC: BACK"
		_message.add_theme_color_override("font_color", COLOR_DIM)

	for i in _buttons.size():
		var enabled := i != BUTTON_START or error_text == ""
		_set_color(_buttons[i], _is_selected(ROW_BUTTONS, i), COLOR_NORMAL if enabled else COLOR_DIM)
	_buttons[BUTTON_TEST].text = "STOP" if _testing else "TEST"
	_place_highlight()


func _is_selected(row: int, col: int) -> bool:
	return _row == row and _col == col and !_testing


func _set_color(label: Label, selected: bool, normal := COLOR_NORMAL):
	label.add_theme_color_override("font_color", COLOR_SELECTED if selected else normal)


func _place_highlight():
	_highlight.visible = !_testing
	var rect := Rect2()
	if _row == ROW_BUTTONS:
		rect = Rect2(BUTTON_X[_col], Y_BUTTONS, BUTTON_WIDTH, ROW_HEIGHT)
	else:
		var y: float = Y_DEVICE if _row == ROW_DEVICE else Y_FIRST_KEY + ROW_HEIGHT * (_row - ROW_FIRST_KEY)
		rect = Rect2(_columns[_col], y, _column_width, ROW_HEIGHT)
	# The Pixeled line is taller than ROW_HEIGHT: its text sits lower
	rect.position.y += HIGHLIGHT_OFFSET_Y
	_highlight.position = rect.position
	_highlight.size = rect.size


func _input(event: InputEvent):
	if _leaving:
		return
	if _capturing:
		_capture(event)
		return
	if _testing:
		# The keys drive the test players, only Esc stops the test
		if event.is_action_pressed("ui_cancel"):
			set_testing(false)
			get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_up"):
		_move(-1)
	elif event.is_action_pressed("ui_down"):
		_move(1)
	elif event.is_action_pressed("ui_left"):
		_horizontal(-1)
	elif event.is_action_pressed("ui_right"):
		_horizontal(1)
	elif event.is_action_pressed("ui_cancel"):
		_leave(false)
	elif event.is_action_pressed("ui_accept"):
		activate()
	elif event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion:
		# Nothing else reaches the menu behind
		pass
	else:
		return
	get_viewport().set_input_as_handled()


func _capture(event: InputEvent):
	var profile := _profile(_col)
	var action: String = GlobalInput.PLAYER_ACTIONS[_row - ROW_FIRST_KEY]
	if GlobalInput.is_keyboard(profile):
		if event is InputEventKey and event.pressed and !event.echo:
			if event.keycode != KEY_ESCAPE:
				GlobalInput.set_key(profile, action, GlobalInput.keycode_from_event(event))
				GlobalAudio.play_sfx("ui_select")
			_end_capture()
		elif event is InputEventJoypadButton and event.pressed:
			_end_capture()
		return
	var cancel: bool = event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE
	if event is InputEventJoypadButton and event.pressed and event.button_index in [JOY_BUTTON_START, JOY_BUTTON_BACK]:
		cancel = true
	if !cancel:
		if !(event is InputEventJoypadButton) or event.device != GlobalInput.gamepad_for(profile):
			get_viewport().set_input_as_handled()
			return
		var button := GlobalInput.button_from_event(event)
		if button < 0:
			get_viewport().set_input_as_handled()
			return
		GlobalInput.set_button(profile, action, button)
		GlobalAudio.play_sfx("ui_select")
	_end_capture()


func _end_capture():
	_capturing = false
	refresh()
	get_viewport().set_input_as_handled()


func _move(direction: int):
	var rows := selectable_rows()
	var index := rows.find(_row)
	var previous := _row
	_row = rows[wrapi(index + direction, 0, rows.size())]
	if _row == ROW_BUTTONS and previous != ROW_BUTTONS:
		_col = BUTTON_START
	elif previous == ROW_BUTTONS and _row != ROW_BUTTONS:
		_col = 0
	GlobalAudio.play_sfx("ui_move")
	refresh()


func _horizontal(direction: int):
	var count := BUTTON_TEXTS.size() if _row == ROW_BUTTONS else _profiles.size()
	if count <= 1:
		if _row == ROW_DEVICE:
			activate()
		return
	_col = wrapi(_col + direction, 0, count)
	if !selectable_rows().has(_row):
		_row = ROW_DEVICE
	GlobalAudio.play_sfx("ui_move")
	refresh()


func activate():
	match _row:
		ROW_DEVICE:
			var profile := _profile(_col)
			var device: int = GlobalInput.Device.GAMEPAD if GlobalInput.is_keyboard(profile) else GlobalInput.Device.KEYBOARD
			GlobalInput.set_device(profile, device)
			GlobalAudio.play_sfx("ui_move")
			refresh()
		ROW_BUTTONS:
			match _col:
				BUTTON_TEST:
					set_testing(!_testing)
				BUTTON_START:
					_start()
				BUTTON_BACK:
					_leave(false)
		_:
			var profile := _profile(_col)
			var action: String = GlobalInput.PLAYER_ACTIONS[_row - ROW_FIRST_KEY]
			if !GlobalInput.is_remappable(profile, action):
				return
			if GlobalInput.is_keyboard(profile) or GlobalInput.gamepad_for(profile) >= 0:
				_capturing = true
				GlobalAudio.play_sfx("ui_move")
				refresh()


func _start():
	if GlobalInput.validation_error(_two_players) != "":
		GlobalAudio.play_sfx("empty")
		_shake_message()
		return
	_leave(true)


func _shake_message():
	if _message_tween:
		_message_tween.kill()
	_message_tween = create_tween()
	for offset in [-3, 3, -2, 2, 0]:
		_message_tween.tween_property(_message, "position:x", float(offset), 0.04)


func _leave(start: bool):
	if _leaving:
		return
	_leaving = true
	set_testing(false)
	GlobalInput.save_config()
	if start:
		start_pressed.emit()
	else:
		back_pressed.emit()
