extends Button
class_name TouchToggle

# On-screen touch controls on/off, saved (as TACTILE in Beat and Match to Pass)

const ICON_ON = preload("res://src/UI/Controls/Shared/checkbox_on.png")
const ICON_OFF = preload("res://src/UI/Controls/Shared/checkbox_off.png")


func _ready():
	if GlobalInput.is_firetv():
		visible = false
		return
	pressed.connect(func(): GlobalInput.set_touch_mode(!GlobalInput.is_touch_mode(), true))
	GlobalInput.touch_mode_changed.connect(_refresh)
	_refresh(GlobalInput.is_touch_mode())


func _refresh(enabled: bool):
	icon = ICON_ON if enabled else ICON_OFF
	text = "TOUCH"
