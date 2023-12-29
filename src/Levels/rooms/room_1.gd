extends Node2D

@onready var width=$ColorRect.get_rect().size.x

@onready var canonRex:CanonRex=$CanonRex

func _on_visible_on_screen_notifier_2d_screen_entered():
	canonRex.enable()
	pass # Replace with function body.


func _on_visible_on_screen_notifier_2d_screen_exited():
	canonRex.disable()
	pass # Replace with function body.
