extends StateMachine
class_name PlayerStateMachine

const STATE_IDLE="StateIdle"
const STATE_WALKING="StateWalking"
const STATE_JUMP="StateJump"
const STATE_FALL="StateFall"
const STATE_EDGE="StateEdge"


func _ready():
	available_state_name_list=[
		STATE_IDLE,
		STATE_WALKING,
		STATE_JUMP,
		STATE_FALL,
		STATE_EDGE
	]
	super.init()
	
