extends Node2D

@export var target:PackedScene

# Called when the node enters the scene tree for the first time.
func _ready():
	pass



func _on_timer_timeout():
	GlobalTransition.change_scene_to_packed(target)
