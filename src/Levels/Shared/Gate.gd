extends StaticBody2D

@onready var _animationPlayer=$AnimationPlayer
@onready var _light=$light

@onready var _light_opened=$light/opened
@onready var _light_closed=$light/closed

@onready var _light_arrow=$LightArrow


var _is_open=false

func _ready():
	_light_arrow.visible=true


func open():
	_animationPlayer.play("Open")
	_is_open=true
	switch_light()
	_light_arrow.visible=false

func close():
	_animationPlayer.play("Close")
	_is_open=false
	switch_light()
	_light_arrow.visible=true

func _on_area_2d_gate_opened():
	if GlobalInput.is_press_action_button():
		if _is_open:
			close()
		else:
			open()
	pass # Replace with function body.

func switch_light():
	for childLoop in _light.get_children():
		childLoop.visible=false
		
		if _is_open:
			_light_opened.visible=true
		else:
			_light_closed.visible=true
