extends CharacterBody2D
class_name motorbike_endlevel

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

@export var _camera:Camera2D

@export var _playerAnimationPlayer:AnimationPlayer
@onready var PlayerFromLeftPath:Path2D=$PlayerAnimation/FromLeftPath2D
@onready var PlayerOnBike:Sprite2D=$playerOnBike

@export var _sheepAnimationPlayer:AnimationPlayer
@onready var SheepFromLeftPath:Path2D=$SheepAnimation/Path2D
@onready var SheepOnBike:Sprite2D=$sheepOnBike

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")


func _ready():
	_playerAnimationPlayer.play("Idle")
	PlayerFromLeftPath.visible=false
	SheepFromLeftPath.visible=false
	PlayerOnBike.visible=false
	SheepOnBike.visible=false

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	if PlayerOnBike.visible and SheepOnBike.visible:
		velocity.x=10

 
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

func finish_install_sheep():
	SheepFromLeftPath.visible=false
	SheepOnBike.visible=true
