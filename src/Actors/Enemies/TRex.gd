extends Enemy

@onready var _animationPlayer=$AnimationPlayer
@onready var _sprite=$Sprite2D

const SPEED = 60.0
const JUMP_VELOCITY = -400.0

var direction=1
var next_direction=0

var life =5

@onready var _state_machine:TRexStateMachine = $StateMachine

@export var speed:float = SPEED

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")



func _physics_process(delta):
	# Add the gravity.
	if get_current_state().has_gravity:
		#if not is_on_floor():
		velocity.y += gravity * delta
			
	if get_current_state().can_move:
		if direction:
			velocity.x = direction * get_current_speed()
			set_new_state(TRexStateMachine.STATE_WALKING)
			_sprite.flip_h=(direction==-1)
		else:
			set_new_state(TRexStateMachine.STATE_IDLE)
			velocity.x = move_toward(velocity.x, 0, SPEED)

		get_current_state().state_physics_process(delta)
	
		if is_on_wall():
			set_new_state(TRexStateMachine.STATE_TURN)
			if direction == -1:
				position.x+=2
				next_direction=1
			else:
				position.x-=2
				next_direction=-1
			
			velocity.x=0
			direction=0
	else:
		velocity.x=0


	move_and_slide()

func damage():
	set_new_state(TRexStateMachine.STATE_DAMAGED)
	life -=1
	if life <=0:
		set_new_state(TRexStateMachine.STATE_DIE)
		
func finish_die():
	queue_free()
	GlobalEvents.emit_signal("enemy_die",self)

func turn():
	direction=next_direction

func get_current_state()->PlayerState:
	return _state_machine.current_state
	
func set_new_state(new_state):
	_state_machine.set_state(new_state)



func get_current_speed():
	var customSpeed=World.get_custom_data_at(position,"moveSpeed",1)
	if customSpeed==0:
		return SPEED
	
	return (speed*customSpeed)