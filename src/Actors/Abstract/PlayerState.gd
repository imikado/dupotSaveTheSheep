extends Node
class_name PlayerState

var root_state_machine: PlayerStateMachine

@export var animation_name : String

@export var can_move : bool
@export var can_jump : bool

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	
func enter():
	animation_play(animation_name)
	
func animation_play(animation_name:String ):
	root_state_machine.animation_play(animation_name)
	
func state_physics_process(delta):
	pass
	
func exit(next_state):
	root_state_machine.change_to(next_state)
	
func on_animation_finished(anim_name:String):
	animation_play(animation_name)
	
func get_player()->CharacterBody2D:
	return root_state_machine.player

