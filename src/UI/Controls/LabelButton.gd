extends TextureButton

@export var _export_label:String="default"

@onready var _uiLabel:= $Label

var _label_y: float


# Called when the node enters the scene tree for the first time.
func _ready():
	_uiLabel.text=_export_label
	_label_y = _uiLabel.position.y
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	focus_entered.connect(_refresh_label_color, CONNECT_DEFERRED)
	focus_exited.connect(_refresh_label_color, CONNECT_DEFERRED)
	mouse_entered.connect(_refresh_label_color, CONNECT_DEFERRED)
	mouse_exited.connect(_refresh_label_color, CONNECT_DEFERRED)


# Pressed texture is lit from above, push the text 1px down
func _on_button_down():
	_uiLabel.position.y = _label_y + 1


func _on_button_up():
	_uiLabel.position.y = _label_y


func _refresh_label_color():
	var highlighted = has_focus() or is_hovered()
	_uiLabel.add_theme_color_override("font_color", Color(1, 0.839216, 0.360784) if highlighted else Color(0.92549, 0.937255, 1))
