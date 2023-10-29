extends Node
class_name StateMachine


var current_state: Object

@export var animationPlayer:AnimationPlayer
@export var actor:CharacterBody2D


var available_state_name_list=[]
var state_list = {}

func _ready():
	for available_state_name_loop in available_state_name_list:
		var state_loop=get_node(available_state_name_loop)
		state_loop.state_machine = self
		state_list[state_loop.name] = state_loop
		if current_state:
			remove_child(state_loop)
		else:
			current_state = state_loop
	current_state.enter()

func _physics_process(delta):
	current_state.state_physics_process(delta)

func animation_play(animation:String)->void :
	animationPlayer.play(animation)

func animation_stop()->void:
	animationPlayer.stop()

func change_to(state_name):
	set_state(state_name)


func set_state(state_name):
	if(state_name == current_state.name):
		return
	remove_child(current_state)
	current_state = state_list[state_name]
	add_child(current_state)
	current_state.enter()


func _on_animation_player_animation_finished(anim_name):
	current_state.on_animation_finished(anim_name)
	pass # Replace with function body.
