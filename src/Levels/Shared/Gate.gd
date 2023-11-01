extends StaticBody2D

@onready var _animationPlayer=$AnimationPlayer

var _is_open=false

func open():
	_animationPlayer.play("Open")
	_is_open=true

func close():
	_animationPlayer.play("Close")
	_is_open=false

func _on_area_2d_gate_opened():
	if GlobalInput.is_press_action_button():
		if _is_open:
			close()
		else:
			open()
	pass # Replace with function body.
