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
	GlobalAudio.play_sfx("bike_crash", 0.0, 0.0, 0.7)
	setState(STATE.OBSTACLE)
	#isHitingObstacle=true
	#animationPlayer.play('obstacle')
	
func ride():
	setState(STATE.RIDING)
	#animationPlayer.play("riding")
	
func take_desserts(life):
	setState(STATE.TAKE_DESSERTS)

func hited():
	GlobalAudio.play_sfx("bike_crash", 0.05)
	setState(STATE.HITED)
	
func take_water(water_value):
	_pending_water = water_value
	setState(STATE.TAKE_WATER)
	
func commit_water():
	GlobalEvents.player_water_changed.emit(_pending_water)
	_pending_water = 0
	
func commit_desserts():
	GlobalPlayer.increase_life(10)
	GlobalSheep.increase_life(10)
	GlobalEvents.player_health_changed.emit(GlobalPlayer.get_life())
	GlobalEvents.sheep_health_changed.emit(GlobalSheep.get_life())

func isState(stateToCheck) -> bool:
	if _state == stateToCheck:
		return true
	return false

func setState(newState):
	_state = newState
	animationPlayer.play(_animationList[newState])

func _physics_process(delta):
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
	
	
	if isState(STATE.JUMPING) and isOnTheFloor():
		setState(STATE.JUMP_END)
		#jumping=false
		#startJumping=false
		#animationPlayer.play("JumpEnd")
	
	
	if isState(STATE.RIDING) and GlobalInput.is_press_jump_button():
		GlobalAudio.play_sfx("jump", 0.05, 0.0, 0.85)
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
		GlobalEvents.player_gameover.emit()
	
