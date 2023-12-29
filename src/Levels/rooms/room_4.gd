extends Node2D

@onready var width=$ColorRect.get_rect().size.x
@onready var animationPlayer:AnimationPlayer=$AnimationPlayer


var opened=true

func open():
	print('open')
	opened=true
	animationPlayer.play_backwards("goup")


func is_open():
	return opened
	
func close():
	print('close')
	opened=false
	animationPlayer.play("goup")
	return
