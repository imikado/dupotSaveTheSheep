extends StateMachine
class_name TRexStateMachine

const STATE_IDLE="StateIdle"
const STATE_WALKING="StateWalking"
const STATE_FALL="StateFall"
const STATE_TURN="StateTurn"
const STATE_DAMAGED="StateDamaged"
const STATE_DIE="StateDie"
const STATE_ATTACK="StateAttack"
const STATE_SPAWN="StateSpawn"

const ANIM_IDLE='Idle';
const ANIM_WALKING='Walking';


func _ready():
	available_state_name_list=[
		
		STATE_WALKING,
		STATE_IDLE,
		STATE_TURN,
		STATE_DAMAGED,
		STATE_DIE,
		STATE_ATTACK,
		STATE_SPAWN
		#STATE_FALL
	]
	super.init()
	
