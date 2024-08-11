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

@onready var hud=$HUD

@export var Obstacle:PackedScene
@export var WaterBottle:PackedScene

var _nextLevel="res://src/UI/Screens/Menu.tscn"

var _countDown=10

const XBETWEEN_OBSTACLE=250
var _xBetweenObstacle=50

const XBETWEEN_WATERBOTTLE=1240
var _xBetweenWaterbottle=50

var _yStart=0

# Called when the node enters the scene tree for the first time.
func _ready():
	_endBonusLayer.visible=false
	screen_size=get_window().size
	camera_start_x=_camera.position.x
	
	_yStart=_player.position.y
	
	GlobalEvents.connect("player_take_water_bottle",on_player_take_water_bottle)
	
	GlobalEvents.connect("player_water_changed",on_player_water_changed)
	
	hud.set_score(GlobalPlayer.get_score())
	hud.set_water(GlobalPlayer.get_water())
	hud.set_player_life(GlobalPlayer.get_life())
	hud.set_sheep_life(GlobalSheep.get_life())

func on_player_take_water_bottle(water_value):
	_player.take_water(water_value)

func on_player_water_changed(new_value):
	hud.set_water(new_value)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	var speed=MAX_SPEED*delta

	_player.position.x+=speed
	_camera.position.x+=speed
	
	shouldSpawnObstacle()
	shouldSpawnWaterBottle()
	
	var distance_between_ground=_camera.position.x - camera_start_x - _ground.position.x 
	
	if distance_between_ground >= GROUND_WIDTH:
		_ground.position.x+=GROUND_WIDTH
		
	#print(_camera.position.x)
	#print(_ground.position.x)
	#print("distance_between:",distance_between_ground)
	#print(screen_size.x)

	pass

func shouldSpawnObstacle():
	_xBetweenObstacle-=1
	
	if _xBetweenObstacle<=0:
		_xBetweenObstacle=XBETWEEN_OBSTACLE
		
		var newObstacle=Obstacle.instantiate()
		add_child(newObstacle)
		
		newObstacle.position.x=_player.position.x+XBETWEEN_OBSTACLE+GROUND_WIDTH
		newObstacle.position.y=_yStart+34
		
func shouldSpawnWaterBottle():
	_xBetweenWaterbottle-=1
	
	if _xBetweenWaterbottle<=0:
		_xBetweenWaterbottle=XBETWEEN_WATERBOTTLE
		
		var newWaterBottle=WaterBottle.instantiate()
		add_child(newWaterBottle)
		
		newWaterBottle.position.x=_player.position.x+XBETWEEN_WATERBOTTLE+GROUND_WIDTH
		newWaterBottle.position.y=_yStart+30

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
