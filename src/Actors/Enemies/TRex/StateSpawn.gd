extends EnemyState

func on_animation_finished(_anim_name:String):
	exit(TRexStateMachine.STATE_WALKING)
