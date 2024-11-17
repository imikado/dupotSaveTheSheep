extends Node2D

@export var RoomStart:PackedScene
@export var Room1:PackedScene
@export var Room2:PackedScene
@export var Room3:PackedScene
@export var Room4:PackedScene
@export var RoomEnd:PackedScene

@export var NextLevel:PackedScene

@onready var hud=$SubViewportContainer/SubViewport/HUD

@onready var _rooms:Node2D=$SubViewportContainer/SubViewport/rooms

@onready var player:Player=$SubViewportContainer/SubViewport/Player
@onready var sheep:Sheep=$SubViewportContainer2/SubViewport/Sheep

@onready var subviewPortMain= $SubViewportContainer/SubViewport
@onready var subViewPortSheep=$SubViewportContainer2/SubViewport

@export var gameOverScene:PackedScene


var score:int=0

var roomNumber=-1

@onready var roomList:Array[PackedScene]=[Room1,Room2,Room3]

var gameover=false

var debugN=3

var alt=0

var max_room=9

func get_room():
	
	roomNumber+=1
	if roomNumber>=roomList.size():
		roomNumber=0
 	 
	if roomNumber==2:
		if alt==0:
			alt=1
			return Room4
		else:
			alt=0	
	
	return roomList[roomNumber]

	
func debug_hook():
	if GlobalGame.is_debug():
		player.global_position.x+=3100
		#player.global_position.y=0
		
		sheep.global_position.x+=3110


# Called when the node enters the scene tree for the first time.
func _ready():
	
	var world=subviewPortMain.find_world_2d()
	subViewPortSheep.world_2d=world
	
	print('main loaded')

	GlobalPlayer.set_actor(player)
	
	GlobalEvents.player_gameover.connect(on_player_gameover)
	
	GlobalEvents.connect("enemy_die",on_enemy_die)

	GlobalEvents.connect("player_take_water_bottle",on_player_take_water_bottle)

	GlobalEvents.connect("player_water_changed",on_player_water_changed)

	GlobalEvents.player_take_damage.connect(on_player_take_damage)

	GlobalEvents.sheep_take_damage.connect(on_sheep_take_damage)

	GlobalEvents.player_increase_life.connect(on_player_increase_life)

	GlobalEvents.end_level.connect(on_end_level)
	

	hud.set_score(GlobalPlayer.get_score())
	hud.set_water(GlobalPlayer.get_water())
	hud.set_player_life(GlobalPlayer.get_life())
	hud.set_sheep_life(GlobalSheep.get_life())

	#rooms
	var currentX=0
	
	var roomStart=RoomStart.instantiate()
	
	_rooms.add_child(roomStart)
	
	roomStart.global_position.x=roomStart.width*-1
	roomStart.global_position.y=0
	
	for i in range(1,9):
		var roomLoop=get_room().instantiate()
		
		_rooms.add_child(roomLoop)
		
		roomLoop.global_position.x=currentX
		roomLoop.global_position.y=0
		
		if i == 1:
			roomLoop.set_decor_visible(true)
	
		currentX+=roomLoop.width
	
	var roomEnd=RoomEnd.instantiate()
	_rooms.add_child(roomEnd)
	
	roomEnd.global_position.x=currentX
	roomEnd.global_position.y=0	
	
	player.global_position.x+=20
	#player.global_position.y=0
	
	sheep.global_position.x=-10
	#sheep.global_position.y=0
	
	hud.max_x=currentX+roomEnd.width

	debug_hook()

	
func on_enemy_die(enemy):
	GlobalPlayer.increase_score(enemy.get_points())
	hud.set_score(GlobalPlayer.get_score())
	
func on_player_water_changed(new_value):
	hud.set_water(new_value)

func on_player_take_water_bottle(water_value):
	player.take_water(water_value)

func on_player_take_damage(damage):
	GlobalPlayer.decrease_life(damage)
	hud.set_player_life(GlobalPlayer.get_life() )
	if GlobalPlayer.get_life() <=0:
		on_player_gameover()


func on_player_increase_life(value):
	GlobalPlayer.increase_life(value)
	hud.set_player_life(GlobalPlayer.get_life() )
	

func on_sheep_take_damage(damage):
	GlobalSheep.decrease_life(damage)
	hud.set_sheep_life(GlobalSheep.get_life() )
	if GlobalSheep.get_life() <=0:
		on_player_gameover()

func on_player_gameover():
	if !gameover:
		print("game over level")
		gameover=true
		get_tree().change_scene_to_packed(gameOverScene)
	


func _on_label_button_button_down():
	on_player_gameover()
	pass # Replace with function body.


func _on_timer_timeout():
	on_player_gameover()
	pass # Replace with function body.


func on_end_level():
	var screenshotImage = get_viewport().get_texture().get_image()
	var screenshotTexture = ImageTexture.create_from_image(screenshotImage)

	GlobalGame.set_last_screenshot(screenshotTexture)
	GlobalTransition.change_scene_to_packed(NextLevel)
