extends Node

@export var _camera:Camera2D
@export var _player:CharacterBody2D
@export var _ground:StaticBody2D

const MAX_SPEED := 150.0
const GROUND_WIDTH:=500.0

var screen_size:Vector2i
var camera_start_x=0

@onready var _endBonusLayer:Control=$Camera2D/BonusControl
@onready var _countDownTimer:Timer=$countDownTimer
@onready var _timeLeftLabel:Label=$Camera2D/Control/timeLeftLabel

var _nextLevel="res://src/UI/Screens/Menu.tscn"

var _countDown=10

# Called when the node enters the scene tree for the first time.
func _ready():
	_endBonusLayer.visible=false
	screen_size=get_window().size
	camera_start_x=_camera.position.x
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	var speed=MAX_SPEED*delta

	_player.position.x+=speed
	_camera.position.x+=speed
	
	var distance_between_ground=_camera.position.x - camera_start_x - _ground.position.x 
	
	if distance_between_ground >= GROUND_WIDTH:
		_ground.position.x+=GROUND_WIDTH
		
	#print(_camera.position.x)
	#print(_ground.position.x)
	#print("distance_between:",distance_between_ground)
	#print(screen_size.x)

	pass



func _on_play_button_pressed():
	get_tree().change_scene_to_file(_nextLevel)
	pass # Replace with function body.


func _on_count_down_timer_timeout():
	_countDown-=1
	if _countDown<0:
		_countDownTimer.stop()
		set_process(false)
		_endBonusLayer.visible=true
		return
	
	_timeLeftLabel.text=str(_countDown)
	
	pass # Replace with function body.
