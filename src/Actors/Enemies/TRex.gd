extends Enemy

@onready var _animationPlayer=$AnimationPlayer
@onready var _sprite=$Sprite2D

const SPEED = 60.0
const JUMP_VELOCITY = -400.0

var direction=1
var next_direction=0

var life =5

var current_state_name=""

@onready var _state_machine:TRexStateMachine = $StateMachine

@export var speed:float = SPEED

@onready var _attackTimer:Timer=$AttackTimer

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var can_attack=true


func _physics_process(delta):
	# Add the gravity.
	if get_current_state().has_gravity:
		#if not is_on_floor():
		velocity.y += gravity * delta
			
	if get_current_state().can_move:
		
		if direction:
			velocity.x = direction * get_current_speed()
			
			if is_on_wall():
				var collision = move_and_collide(velocity * delta)
				if collision:
					var collider=collision.get_collider()
					if collider is Player or collider is Sheep:
						if can_attack:
							set_new_state(TRexStateMachine.STATE_ATTACK)
							move_and_slide()
							collider.hit_damage(10)
							can_attack=false
							_attackTimer.start()
						else:
							set_new_state(TRexStateMachine.STATE_IDLE)
							move_and_slide()
						return
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
	if !alive:
		return
	set_new_state(TRexStateMachine.STATE_DAMAGED)
	life -=1
	if life <=0:
		alive=false
		die()

func spawn():
	set_new_state(TRexStateMachine.STATE_SPAWN)

func die():
	set_new_state(TRexStateMachine.STATE_DIE)
		
func finish_die():
	queue_free()
	GlobalEvents.emit_signal("enemy_die",self)

func turn():
	direction=next_direction

func get_current_state()->PlayerState:
	return _state_machine.current_state
	
func set_new_state(new_state):
	current_state_name=new_state
	_state_machine.set_state(new_state)
	#print("new state:"+new_state)



func get_current_speed():
	
	return SPEED


func _on_attack_timer_timeout():
	can_attack=true
	pass # Replace with function body.
