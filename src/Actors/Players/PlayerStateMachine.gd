extends StateMachine
class_name PlayerStateMachine

const STATE_IDLE="StateIdle"
const STATE_WALKING="StateWalking"
const STATE_JUMP="StateJump"
const STATE_FALL="StateFall"

const ANIM_IDLE='Idle';
const ANIM_WALKING='Walking';


func _ready():
	available_state_name_list=[
		STATE_IDLE,
		STATE_WALKING,
		STATE_JUMP,
		STATE_FALL
	]
	super._ready()
	
