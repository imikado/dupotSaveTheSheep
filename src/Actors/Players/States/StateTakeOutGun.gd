extends  PlayerState


func on_animation_finished(anim_name:String):
	exit(PlayerStateMachine.STATE_GUNOUT)
 

