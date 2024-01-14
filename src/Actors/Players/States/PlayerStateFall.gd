extends PlayerState
class_name PlayerStateFall


func state_process(_delta):
	if get_actor().is_on_floor():
		exit(PlayerStateMachine.STATE_IDLE)
