extends StateMachine
class_name CanonRexStateMachine

const STATE_IDLE="StateIdle"
const STATE_SHOOTING="StateShooting"
const STATE_DIE="StateDie"
const STATE_DAMAGED="StateDamaged"

func _ready():
	available_state_name_list=[
		
		STATE_IDLE,
		STATE_SHOOTING,
		STATE_DAMAGED,
		STATE_DIE
		
	]
	super.init()
	
