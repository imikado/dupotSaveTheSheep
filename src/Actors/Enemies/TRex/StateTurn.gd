extends EnemyState
class_name TRexStateTurn

func on_animation_finished(anim_name:String):
	get_actor().turn()
	exit(TRexStateMachine.STATE_WALKING)
