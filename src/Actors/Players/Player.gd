extends CharacterBody2D


const SPEED = 100.0
const JUMP_VELOCITY = -200.0

const INPUT_ATTACK='ui_accept'
const INPUT_JUMP='ui_select'

const INPUT_LEFT='ui_left'
const INPUT_RIGHT='ui_right'
const INPUT_UP='ui_up'
const INPUT_DOWN='ui_down'

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var _state_machine:PlayerStateMachine = $StateMachine
@onready var _sprite:Sprite2D = $Sprite2D


func _physics_process(delta):
	
	update_gravity(delta)
	
	if get_current_state().can_move:
		update_move(delta)
	
	if get_current_state().can_jump:
		update_jump(delta)
		
	get_current_state().state_physics_process(delta)

	process_move()
	
func process_jump(delta):
	velocity.y = JUMP_VELOCITY

#func _physics_process(delta):
func update_gravity(delta):
	# Add the gravity.
	if not is_on_floor() and get_current_state().name!=PlayerStateMachine.STATE_JUMP:
		set_new_state(PlayerStateMachine.STATE_FALL)
		velocity.y += gravity * delta

func update_jump(delta):
	if Input.is_action_just_pressed(INPUT_JUMP) and is_on_floor():
		set_new_state(PlayerStateMachine.STATE_JUMP)

	


func update_move(delta):
	var currentSpeed= get_current_speed()
	
	var direction = Input.get_axis(INPUT_LEFT, INPUT_RIGHT)
	if direction:
		set_new_state(PlayerStateMachine.STATE_WALKING)
		velocity.x = direction * currentSpeed
		
		_sprite.flip_h=(direction==-1)
	else:
		set_new_state(PlayerStateMachine.STATE_IDLE)
		velocity.x = move_toward(velocity.x, 0, currentSpeed)


func process_move():
	move_and_slide()
	
func set_new_state(new_state):
	_state_machine.set_state(new_state)

func get_current_state()->PlayerState:
	return _state_machine.current_state
	
func get_current_speed():
	var customSpeed=World.get_custom_data_at(position,"moveSpeed",1)
	
	return (SPEED*customSpeed)


	
	
