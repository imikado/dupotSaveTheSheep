extends  PlayerState
class_name PlayerStateIdle

var iteration=0

func on_animation_finished(anim_name:String):
	iteration+=1
	
	if(iteration>8):
		iteration=0
		exit(PlayerStateMachine.STATE_IMPATIENT)
	else:
		enter()
		

 

