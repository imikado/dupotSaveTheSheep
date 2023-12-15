extends Node
class_name State

var state_machine: StateMachine

@export var animation_name : String

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	
func enter():
	animation_play(animation_name)
	
func animation_play(animation_name_to_play:String ):
	state_machine.animation_play(animation_name_to_play)
	
func animation_reset():
	state_machine.animation_reset()
	
func state_physics_process(_delta):
	pass
	
func exit(next_state):
	state_machine.change_to(next_state)
	
func on_animation_finished(_animation_name_finished:String):
	animation_play(animation_name)
	
func get_actor()->CharacterBody2D:
	return state_machine.actor

