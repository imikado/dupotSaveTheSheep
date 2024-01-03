extends EnemyState

func on_animation_finished(_anim_name:String):
	#get_actor().spawn_fireball()
	exit(CanonRexStateMachine.STATE_IDLE)
