extends StateMachine
class_name SheepStateMachine

const STATE_IDLE="StateIdle"
const STATE_WALKING="StateWalking"
const STATE_FALL="StateFall"
const STATE_TURN="StateTurn"
const STATE_DAMAGED="StateDamaged"


const ANIM_IDLE='Idle';
const ANIM_WALKING='Walking';


func _ready():
	available_state_name_list=[
		
		STATE_WALKING,
		STATE_IDLE,
		STATE_TURN,
		STATE_DAMAGED
		#STATE_FALL
	]
	super.init()
	
