extends EnemyState


func on_animation_finished(_anim_name:String):
	get_actor().turn()
	exit(TRexStateMachine.STATE_WALKING)
