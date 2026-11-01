extends StaticBody2D

@onready var _animationPlayer=$AnimationPlayer
@onready var _light=$light

@onready var _light_opened=$light/opened
@onready var _light_closed=$light/closed

@onready var _light_arrow=$LightArrow


var _is_open=false

func _ready():
	_light_arrow.visible=true
	switch_light(false)


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


func switch_light(blink:=true):
	_light_opened.visible=_is_open
	_light_closed.visible=!_is_open

	# The new light blinks so the change of state is noticed
	if blink:
		var light = _light_opened if _is_open else _light_closed
		var tween = create_tween()
		for i in 3:
			tween.tween_property(light, "modulate:a", 0.15, 0.06)
			tween.tween_property(light, "modulate:a", 1.0, 0.06)

func action():
	GlobalAudio.play_sfx("gate")
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
