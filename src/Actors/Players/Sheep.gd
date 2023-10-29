extends CharacterBody2D

const SPEED = 100.0
const JUMP_VELOCITY = -400.0

@export var speed:float = SPEED

@onready var _state_machine:SheepStateMachine = $StateMachine
@onready var _sprite=$Sprite2D

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var direction=1
var next_direction=0

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta
		
	if get_current_state().can_move:
		if direction:
			velocity.x = direction * get_current_speed()
			set_new_state(SheepStateMachine.STATE_WALKING)
			_sprite.flip_h=(direction==-1)
		else:
			set_new_state(SheepStateMachine.STATE_IDLE)
			velocity.x = move_toward(velocity.x, 0, SPEED)

		get_current_state().state_physics_process(delta)

	move_and_slide()
	
	if is_on_wall():
		set_new_state(SheepStateMachine.STATE_TURN)
		if direction == -1:
			position.x+=2
			next_direction=1
		else:
			position.x-=2
			next_direction=-1
		
		velocity.x=0
		direction=0
		
		
func turn():
	direction=next_direction

	
func get_current_state()->PlayerState:
	return _state_machine.current_state
	
func set_new_state(new_state):
	_state_machine.set_state(new_state)

func get_current_speed():
	var customSpeed=World.get_custom_data_at(position,"moveSpeed",1)
	
	return (speed*customSpeed)
	
