extends CanvasLayer

# On-screen touch controls, shown automatically in touch mode (see GlobalInput).
# Each button presses an existing input action, the game logic is unchanged.

const BUTTON_ALPHA := 0.55
const BUTTON_PRESSED_ALPHA := 0.95

@export var moveButtons:=true
@export var jumpButton:=true
@export var attackButton:=true
@export var actionButton:=true

func _ready() -> void:
	$joystick.visible=moveButtons
	$buttons/attack.visible=attackButton
	$buttons/jump.visible=jumpButton
	$buttons/action.visible=actionButton

	for button in $buttons.get_children():
		button.modulate.a = BUTTON_ALPHA
		button.pressed.connect(_on_button_pressed.bind(button, true))
		button.released.connect(_on_button_pressed.bind(button, false))

	GlobalInput.touch_mode_changed.connect(_on_touch_mode_changed)
	_on_touch_mode_changed(GlobalInput.is_touch_mode())

func _on_touch_mode_changed(enabled: bool) -> void:
	visible = enabled or GlobalGame.isControlsEnabled()
	if !visible:
		$joystick.reset()

# Pressed feedback: the button lights up on top of its pressed texture
func _on_button_pressed(button: TouchScreenButton, isPressed: bool) -> void:
	button.modulate.a = BUTTON_PRESSED_ALPHA if isPressed else BUTTON_ALPHA
	if isPressed:
		GlobalAudio.play_sfx("ui_move")
