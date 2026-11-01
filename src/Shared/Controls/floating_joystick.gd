extends Node2D

# Floating joystick: it starts where the thumb lands in its zone and drives
# ui_left / ui_right (the game does not use up/down).

# Knob travel and dead zone, in game pixels
const TRAVEL := 11.0
const DEAD_ZONE := 4.0
const BASE_HALF := 20.0
const IDLE_ALPHA := 0.35
const ACTIVE_ALPHA := 0.8

## Area of the screen that starts the joystick (game pixels)
@export var zone := Rect2(0, 60, 240, 210)
## Area the base must not cover (sheep inset of level 1)
@export var avoid := Rect2(0, 203, 156, 67)
## Where the base waits, as a hint, when no thumb is on it
@export var restPosition := Vector2(182, 238)

@onready var _base: Sprite2D = $base
@onready var _knob: Sprite2D = $base/knob

var _touchIndex := -1
var _origin := Vector2.ZERO
var _pressed := {}

func _ready() -> void:
	reset()

func _exit_tree() -> void:
	reset()

func _notification(what: int) -> void:
	# The release of the thumb is lost while the game is paused
	if what == NOTIFICATION_PAUSED:
		reset()

func _input(event: InputEvent) -> void:
	if !is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		if event.pressed and _touchIndex == -1 and zone.has_point(event.position):
			_touchIndex = event.index
			_origin = event.position
			_base.position = _visible_position(_origin)
			modulate.a = ACTIVE_ALPHA
			_update(event.position)
		elif !event.pressed and event.index == _touchIndex:
			reset()
	elif event is InputEventScreenDrag and event.index == _touchIndex:
		_update(event.position)

func reset() -> void:
	_touchIndex = -1
	for action in _pressed.keys():
		Input.action_release(action)
	_pressed.clear()
	if is_node_ready():
		_base.position = restPosition
		_knob.position = Vector2.ZERO
		modulate.a = IDLE_ALPHA

func _update(thumb: Vector2) -> void:
	var delta := thumb - _origin
	if delta.length() > TRAVEL:
		# The base follows the thumb, so going back the other way reacts at once
		_origin = thumb - delta.normalized() * TRAVEL
		delta = thumb - _origin
		_base.position = _visible_position(_origin)
	_knob.position = delta.round()
	_set_action(GlobalInput.INPUT_LEFT, delta.x < -DEAD_ZONE)
	_set_action(GlobalInput.INPUT_RIGHT, delta.x > DEAD_ZONE)

func _set_action(action: String, enabled: bool) -> void:
	if enabled == _pressed.has(action):
		return
	if enabled:
		_pressed[action] = true
		Input.action_press(action)
	else:
		_pressed.erase(action)
		Input.action_release(action)

# Under the thumb, except over the sheep inset: then just to its right
func _visible_position(point: Vector2) -> Vector2:
	if avoid.grow(BASE_HALF).has_point(point):
		point.x = avoid.end.x + BASE_HALF
	return point.round()
