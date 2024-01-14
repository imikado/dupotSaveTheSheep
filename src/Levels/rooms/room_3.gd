extends Node2D

@onready var width=$ColorRect.get_rect().size.x

@onready var drone=$decor/drone

@onready var _decor:Node2D=$decor

var enabled=false

func _ready():
	set_decor_visible(false)
	set_drone_process(false)

func set_decor_visible(state):
	_decor.visible=state

func _on_visible_on_screen_notifier_2d_screen_entered():
	set_decor_visible(true)
	enabled=true
	set_drone_process(enabled)

func _on_visible_on_screen_notifier_2d_screen_exited():
	set_decor_visible(false)
	enabled=false
	set_drone_process(enabled)

func set_drone_process(processEnabled):
	if processEnabled:
		drone.enable()
	else:
		drone.disable()
