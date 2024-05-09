extends CharacterBody2D


const JUMP_VELOCITY = -300.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var animationPlayer:=$AnimationPlayer

var jumping=false
var startJumping=false
var canJump=true
var jumpX=100
var deltaX=0
var groundPositionY=0.0

func _ready():
	animationPlayer.play("riding")
	groundPositionY=position.y

func processJump():
	velocity.y=JUMP_VELOCITY
	startJumping=true
	jumping=true

func processEndJump():
	startJumping=false
	canJump=true

func isOnTheFloor():
	return (velocity.y==0)

func _process(delta):
	# Add the gravity.
	if not isOnTheFloor():
		velocity.y += gravity * delta*0.8
		
	var jumpSizeX=jumpX*delta
		
	if startJumping:
		position.x+=jumpSizeX
		deltaX+=jumpSizeX
		
	if !startJumping and deltaX>0:
		jumpSizeX=jumpSizeX/2
		if jumpSizeX > deltaX:
			position.x-=deltaX
			deltaX=0
		else:
			position.x-=jumpSizeX
			deltaX-=jumpSizeX
	
	print(velocity.y)
	print(position.y)
	
	if jumping and isOnTheFloor():
		jumping=false
		startJumping=false
		print('floor')
		animationPlayer.play("JumpEnd")
		
	if !jumping and canJump and GlobalInput.is_press_jump_button():
		$AnimationPlayer.play('JumpStart')
		canJump=false

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
	
