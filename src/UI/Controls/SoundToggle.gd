extends Button
class_name SoundToggle

# Pixel speaker button switching music and effects on/off (same as the M key)

const ICON_ON = preload("res://src/UI/Controls/Shared/icon-sound-on.png")
const ICON_OFF = preload("res://src/UI/Controls/Shared/icon-sound-off.png")


func _ready():
	pressed.connect(GlobalAudio.toggle_sound)
	GlobalAudio.sound_toggled.connect(_refresh)
	_refresh(GlobalAudio.is_sound_enabled())


func _refresh(enabled: bool):
	icon = ICON_ON if enabled else ICON_OFF
	text = "ON" if enabled else "OFF"
