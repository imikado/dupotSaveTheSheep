extends SheepState

func on_animation_finished(_anim_name:String):
	exit(SheepStateMachine.STATE_WALKING)
