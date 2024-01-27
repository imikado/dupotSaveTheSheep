extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0

@export var _playerAnimationPlayer:AnimationPlayer
@export var _sheepAnimationPlayer:AnimationPlayer
@export var _camera:Camera2D
@onready var PlayerFromLeftPath:Path2D=$PlayerAnimation/FromLeftPath2D
@onready var PlayerOnBike:Sprite2D=$playerOnBike
@onready var SheepFromLeftPath:Path2D=$SheepAnimation/Path2D

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")


func _ready():
	_playerAnimationPlayer.play("idle")
	PlayerFromLeftPath.visible=false
	SheepFromLeftPath.visible=false
	PlayerOnBike.visible=false

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

 
	move_and_slide()


func _on_area_2d_body_entered(body):
	if body is Player or body is Sheep:
		body.set_pending_vehicle(self)


func _on_area_2d_body_exited(body):
	if body is Player or body is Sheep:
		body.reset_pending_vehicle()


func player_go_from_left():
	switch_own_camera()
	PlayerFromLeftPath.visible=true
	_playerAnimationPlayer.play("player_go_from_left")

func switch_own_camera():
	_camera.enabled=true
	
func finish_install_player():
	PlayerFromLeftPath.visible=false
	PlayerOnBike.visible=true


func sheep_go_from_left():
	SheepFromLeftPath.visible=true
	_sheepAnimationPlayer.play("sheep_go_from_left")
