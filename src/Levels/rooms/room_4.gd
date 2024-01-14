extends Node2D

@onready var width=$ColorRect.get_rect().size.x
@onready var animationPlayer:AnimationPlayer=$decor/AnimationPlayer

@onready var _decor:Node2D=$decor

var opened=true

func _ready():
	set_decor_visible(false)
	
func set_decor_visible(state):
	_decor.visible=state

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


func _on_visible_on_screen_notifier_2d_screen_entered():
	set_decor_visible(true)
	pass # Replace with function body.


func _on_visible_on_screen_notifier_2d_screen_exited():
	set_decor_visible(false)
	pass # Replace with function body.
