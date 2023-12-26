extends Node2D

@onready var width=$ColorRect.get_rect().size.x
@onready var animationPlayer:AnimationPlayer=$AnimationPlayer

var opened=false

func open():
	print('open')



func is_open():
	return opened
	
func close():
	animationPlayer.play("goup")
	return
