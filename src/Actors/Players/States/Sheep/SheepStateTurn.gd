extends SheepState
class_name SheepStateTurn

func on_animation_finished(anim_name:String):
	get_actor().turn()
	exit(SheepStateMachine.STATE_WALKING)
