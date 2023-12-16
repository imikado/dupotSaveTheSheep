extends Node2D

@onready var width=$ColorRect.get_rect().size.x

@onready var drone=$drone

var enabled=false

func _ready():
	set_drone_physics_process(false)

func _on_visible_on_screen_notifier_2d_screen_entered():
	enabled=true
	set_drone_physics_process(enabled)

func _on_visible_on_screen_notifier_2d_screen_exited():
	enabled=false
	set_drone_physics_process(enabled)

func set_drone_physics_process(processEnabled):
	if processEnabled:
		drone.enable()
	else:
		drone.disable()
