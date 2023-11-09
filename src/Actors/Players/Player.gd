extends CharacterBody2D
class_name Player


const SPEED = 100.0
const JUMP_VELOCITY = -150.0

const AREA='PlayerArea'


var carry_sheep=false

var direction

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var _state_machine:PlayerStateMachine = $StateMachine
@onready var _sprite:Sprite2D = $Sprite2D

@onready var _raycast:RayCast2D=$RayCast2D

@export var _sheep:Sheep 


func _physics_process(delta):
	
	if get_current_state().has_gravity:
		update_gravity(delta)
	
	if get_current_state().can_move:
		update_move(delta)
	else:
		update_min_move(delta)
	
	if get_current_state().can_jump:
		update_jump(delta)
		
	get_current_state().state_physics_process(delta)

	update_carry_sheep()

	process_move()
	
func process_jump(delta):
	velocity.y = JUMP_VELOCITY

#func _physics_process(delta):
func update_gravity(delta):
	# Add the gravity.
	if not is_on_floor():
		set_new_state(PlayerStateMachine.STATE_FALL)
		velocity.y += gravity * delta

func update_jump(delta):
	if GlobalInput.is_press_jump_button() and is_on_floor():
		set_new_state(PlayerStateMachine.STATE_JUMP)

func update_carry_sheep():
	if !carry_sheep and GlobalInput.is_press_carry_button() and is_on_floor():
		if abs(_sheep.position.x - position.x) <30:
			print('carry sheep')
			
			_sheep.be_carried()
			_sheep.position.x=position.x+2
			_sheep.position.y-=35
			_sheep.reparent(self)
			
			add_child(_sheep)
			
			carry_sheep=true
	elif carry_sheep and GlobalInput.is_press_carry_button() and is_on_floor():
		_sheep.reparent(get_parent())
		_sheep.position.x+=10*direction
		_sheep.position.y+=28
		_sheep.bring_back()
		
		carry_sheep=false

func update_move(delta):
	var currentSpeed= get_current_speed()
	
	direction = GlobalInput.get_direction()
	if direction:
		set_new_state(PlayerStateMachine.STATE_WALKING)
		velocity.x = direction * currentSpeed
		
		_sprite.flip_h=(direction==-1)
	else:
		if !_raycast.is_colliding():
			set_new_state(PlayerStateMachine.STATE_EDGE)
			velocity.x = move_toward(velocity.x, 0, currentSpeed)
			print("on edge")
		else:
			if(get_current_state().name!=PlayerStateMachine.STATE_IMPATIENT):
				set_new_state(PlayerStateMachine.STATE_IDLE)
			velocity.x = move_toward(velocity.x, 0, currentSpeed)

func update_min_move(delta):
	if velocity.x!=0:
		return
		
	var currentSpeed= get_current_speed()/2
	
	direction = GlobalInput.get_direction()
	if direction:
		velocity.x = direction *currentSpeed
		
		_sprite.flip_h=(direction==-1)


func process_move():
	move_and_slide()
	
func set_new_state(new_state):
	_state_machine.set_state(new_state)

func get_current_state()->State:
	return _state_machine.current_state
	
func get_current_speed():
	var customSpeed=World.get_custom_data_at(position,"moveSpeed",1)
	
	return (SPEED*customSpeed)


	
	
