extends Node2D

@export var Room1:PackedScene
@export var Room2:PackedScene
@export var Room3:PackedScene

@onready var hud=$HUD

@onready var _rooms:Node2D=$rooms

@export var player:Player
@export var sheep:Sheep

@onready var parallaxLayer=$ParallaxBackground/ParallaxLayer
@onready var parallaxLayerSprite=$ParallaxBackground/ParallaxLayer/Sprite2D

@onready var parallaxLayer2=$ParallaxBackground/ParallaxLayer2
@onready var parallaxLayer2Sprite=$ParallaxBackground/ParallaxLayer2/Sprite2D

var score:int=0

var roomNumber=-1

@onready var roomList:Array[PackedScene]=[Room1,Room2,Room3]

func get_room():
	
	roomNumber+=1
	if roomNumber>=roomList.size():
		roomNumber=0
 	

	 
	return roomList[roomNumber]

# Called when the node enters the scene tree for the first time.
func _ready():	
	
	GlobalEvents.player_gameover.connect(on_player_gameover)
	
	GlobalEvents.connect("enemy_die",on_enemy_die)
	GlobalEvents.connect("player_water_changed",on_player_water_changed)
	
	hud.set_score(GlobalPlayer.get_score())
	hud.set_water(GlobalPlayer.get_water())
	

	#rooms
	var previousWidth=0
	var currentX=0
	
	for i in range(-1,7):
		var roomLoop=get_room().instantiate()
		
		_rooms.add_child(roomLoop)
		
		if i<0:
			currentX-=roomLoop.width
		
		roomLoop.global_position.x=currentX
		roomLoop.global_position.y=0
	
		currentX+=roomLoop.width
	
		var parallaxLayerSpriteLoop=parallaxLayerSprite.duplicate()
		parallaxLayer.add_child(parallaxLayerSpriteLoop)
		parallaxLayerSpriteLoop.global_position.x+=480*i
		
		var parallaxLayerSpriteLoop2=parallaxLayer2Sprite.duplicate()
		parallaxLayer2.add_child(parallaxLayerSpriteLoop2)
		parallaxLayerSpriteLoop2.global_position.x+=480*i
	
	
	#---------
	
	player.global_position.x=20
	player.global_position.y=0
	
	sheep.global_position.x=-10
	sheep.global_position.y=0
	
	
func on_enemy_die(enemy):
	score+=enemy.get_points()
	hud.set_score(score)
	
func on_player_water_changed(new_value):
	hud.set_water(new_value)

func on_player_gameover():
	print('game over')
	get_tree().change_scene_to_file('res://src/UI/Screens/game_over.tscn')
