extends CharacterBody2D
class_name PlayerOnMotorBike

const JUMP_VELOCITY = -300.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var animationPlayer := $AnimationPlayer

enum STATE {RIDING, JUMP_START, JUMPING, JUMP_END, TAKE_WATER, OBSTACLE, TAKE_DESSERTS, HITED}


var _state = STATE.RIDING
var _animationList = {
	STATE.RIDING: 'riding',
	STATE.JUMP_START: 'JumpStart',
	STATE.JUMPING: 'riding',
	STATE.JUMP_END: 'JumpEnd',
	STATE.TAKE_WATER: 'TakeWater',
	STATE.OBSTACLE: 'obstacle',
	STATE.TAKE_DESSERTS: 'TakeDesserts',
	STATE.HITED: 'hited'
}

var jumping = false
var startJumping = false
var canJump = true
var jumpX = 100
var deltaX = 0
var groundPositionY = 0.0
var isHitingObstacle = false

var _pending_water = 0

func _ready():
	groundPositionY = position.y
	ride()
	
func getAnimation(stateToCheck) -> String:
	return _animationList[stateToCheck]

func processJump():
	velocity.y = JUMP_VELOCITY
	setState(STATE.JUMP_START)
	#startJumping=true
	#jumping=true

func processEndJump():
	setState(STATE.RIDING)
	#startJumping=false
	#canJump=true
	#ride()

func isOnTheFloor():
	return (velocity.y == 0)
	
func hitedObstacle():
	setState(STATE.OBSTACLE)
	#isHitingObstacle=true
	print('obstacle')
	#animationPlayer.play('obstacle')
	
func ride():
	setState(STATE.RIDING)
	#animationPlayer.play("riding")
	
func take_desserts(life):
	setState(STATE.TAKE_DESSERTS)

func hited():
	setState(STATE.HITED)
	
func take_water(water_value):
	_pending_water = water_value
	setState(STATE.TAKE_WATER)
	print('player get value' + str(water_value))
	
func commit_water():
	GlobalEvents.emit_signal("player_water_changed", _pending_water)
	_pending_water = 0
	
func commit_desserts():
	print(GlobalPlayer.get_life())
	GlobalPlayer.increase_life(10)
	GlobalSheep.increase_life(10)
	print(GlobalPlayer.get_life())
	GlobalEvents.emit_signal("player_health_changed", GlobalPlayer.get_life())
	GlobalEvents.emit_signal("sheep_health_changed", GlobalSheep.get_life())

func isState(stateToCheck) -> bool:
	if _state == stateToCheck:
		return true
	return false

func setState(newState):
	_state = newState
	animationPlayer.play(_animationList[newState])

func _process(delta):
	# Add the gravity.
	if not isOnTheFloor():
		velocity.y += gravity * delta * 0.8
		
	var jumpSizeX = jumpX * delta
		
	if isState(STATE.JUMP_START):
		position.x += jumpSizeX
		deltaX += jumpSizeX
		
	if !isState(STATE.JUMP_START) and deltaX > 0:
		jumpSizeX = jumpSizeX / 2
		if jumpSizeX > deltaX:
			position.x -= deltaX
			deltaX = 0
		else:
			position.x -= jumpSizeX
			deltaX -= jumpSizeX
	
	#print(velocity.y)
	#print(position.y)
	
	if isState(STATE.JUMPING) and isOnTheFloor():
		setState(STATE.JUMP_END)
		#jumping=false
		#startJumping=false
		#print('floor')
		#animationPlayer.play("JumpEnd")
	
	
	if isState(STATE.RIDING) and GlobalInput.is_press_jump_button():
		setState(STATE.JUMP_START)
		#$AnimationPlayer.play('JumpStart')
		#canJump=false

	# Handle jump.
	#if Input.is_action_just_pressed("ui_accept") and is_on_floor():
	#	velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	#var direction = Input.get_axis("ui_left", "ui_right")
	#if direction:
#		velocity.x = direction * SPEED
#	else:#
	#	velocity.x = move_toward(velocity.x, 0, SPEED)
	move_and_slide()
	

func _on_animation_player_animation_finished(anim_name):
	if anim_name == getAnimation(STATE.JUMP_START):
		setState(STATE.JUMPING)
	elif anim_name == getAnimation(STATE.TAKE_WATER):
		commit_water()
		setState(STATE.RIDING)
	elif anim_name == getAnimation(STATE.TAKE_DESSERTS):
		#commit_water()
		commit_desserts()
		setState(STATE.RIDING)
	elif anim_name == getAnimation(STATE.OBSTACLE):
		GlobalEvents.emit_signal("player_gameover")
	
	pass # Replace with function body.
