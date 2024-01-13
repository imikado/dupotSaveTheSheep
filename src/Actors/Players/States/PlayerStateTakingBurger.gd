extends  PlayerState

func on_animation_finished(_anim_name:String):
	get_actor().commit_increase_life()
	exit(PlayerStateMachine.STATE_IDLE)
