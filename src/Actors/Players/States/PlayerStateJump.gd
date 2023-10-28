extends PlayerState
class_name PlayerStateJump

func state_physics_process(delta):
	get_player().process_jump(delta)

func on_animation_finished(anim_name:String):
	exit(PlayerStateMachine.STATE_FALL)
