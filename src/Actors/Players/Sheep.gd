extends CharacterBody2D
class_name Sheep

const SPEED = 30.0
const JUMP_VELOCITY = -400.0

@export var speed:float = SPEED

@onready var _state_machine:SheepStateMachine = $StateMachine
@onready var _sprite=$Sprite2D

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var direction=1
var last_direction=0
var next_direction=0
var _pending_vehicle=null

func walk_right():
	direction=1
	set_new_state(_state_machine.STATE_WALKING)

func _process(delta):


	if _pending_vehicle!=null:
		
		queue_free()
		
		_pending_vehicle.sheep_go_from_left()	

	# Add the gravity.
	if get_current_state().has_gravity:
		if not is_on_floor():
			velocity.y += gravity * delta
		
	if get_current_state().can_move:
		if direction:
			velocity.x = direction * get_current_speed()
			set_new_state(SheepStateMachine.STATE_WALKING)
			_sprite.flip_h=(direction==-1)
		#else:
		#	set_new_state(SheepStateMachine.STATE_IDLE)
		#	velocity.x = move_toward(velocity.x, 0, SPEED)

		get_current_state().state_process(delta)


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

	move_and_slide()
	
	
		
		
func turn():
	direction=next_direction

func be_carried():
	set_new_state(SheepStateMachine.STATE_IDLE)
	last_direction=direction
	direction=0
	velocity.x=0

func bring_back():
	set_new_state(SheepStateMachine.STATE_WALKING)
	direction=1
	
func get_current_state()->PlayerState:
	return _state_machine.current_state
	
func set_new_state(new_state):
	_state_machine.set_state(new_state)

func get_current_speed():
	return SPEED
	

func hit_damage(damage):
	set_new_state(SheepStateMachine.STATE_DAMAGED)
	
	GlobalEvents.sheep_take_damage.emit(damage)
	

func set_pending_vehicle(pending_vehicle):
	_pending_vehicle=pending_vehicle

func reset_pending_vehicle():
	_pending_vehicle=null

func _on_jump_on_head_area_body_entered(body: Node2D) -> void:
	if body is Player:
		body.process_jump(1) # # Replace with function body.
