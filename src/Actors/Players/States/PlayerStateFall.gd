extends PlayerState
class_name PlayerStateFall


func state_physics_process(delta):
	if get_player().is_on_floor():
		exit(PlayerStateMachine.STATE_IDLE)
