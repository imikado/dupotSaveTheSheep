extends StateMachine
class_name PlayerStateMachine

const STATE_IDLE="StateIdle"
const STATE_WALKING="StateWalking"
const STATE_JUMP="StateJump"
const STATE_FALL="StateFall"
const STATE_EDGE="StateEdge"
const STATE_IMPATIENT="StateImpatient"
const STATE_TAKEOUTGUN="StateTakeOutGun"
const STATE_GUNOUT="StateGunOut"
const STATE_GUNSHOOT="StateGunShoot"
const STATE_DAMAGED="StateDamaged"
const STATE_TAKINGWATER='StateTakingWater'
const STATE_ACTION='StateAction'
const STATE_TAKINGBURGER='StateTakingBurger'

func _ready():
	available_state_name_list=[
		STATE_IDLE,
		STATE_WALKING,
		STATE_JUMP,
		STATE_FALL,
		STATE_EDGE,
		STATE_IMPATIENT,
		STATE_TAKEOUTGUN,
		STATE_GUNOUT,
		STATE_GUNSHOOT,
		STATE_DAMAGED,
		STATE_TAKINGWATER,
		STATE_ACTION,
		STATE_TAKINGBURGER
	]
	super.init()
	
