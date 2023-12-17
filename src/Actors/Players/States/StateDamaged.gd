extends  PlayerState

func on_animation_finished(_anim_name:String):
	exit(PlayerStateMachine.STATE_WALKING)
