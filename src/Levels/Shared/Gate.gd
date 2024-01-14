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


func switch_light():
	for childLoop in _light.get_children():
		childLoop.visible=false
		
		if _is_open:
			_light_opened.visible=true
		else:
			_light_closed.visible=true

func action():
	if _is_open:
		close()
	else:
		open()


func _on_area_2d_body_entered(body):
	if body is Player:
		body.set_pending_action(self)


func _on_area_2d_body_exited(body):
	if body is Player:
		body.reset_pending_action()
