extends PlayerState
class_name PlayerStateJump

func enter():
	super.enter()
	get_actor().start_jump()

func on_animation_finished(_anim_name:String):
	exit(PlayerStateMachine.STATE_FALL)
