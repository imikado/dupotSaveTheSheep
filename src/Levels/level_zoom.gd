extends Node2D

@onready var Room1=load("res://src/Levels/rooms/room_1.tscn")
@onready var Room2=load("res://src/Levels/rooms/room_2.tscn")
@onready var Room3=load("res://src/Levels/rooms/room_3.tscn")

@onready var hud=$HUD

@onready var _rooms:Node2D=$rooms

@export var player:Player
@export var sheep:Sheep

var score:int=0

var roomNumber=-1

@onready var roomList=[Room1,Room2,Room3]

func get_room():
	
	roomNumber+=1
	if roomNumber>=roomList.size():
		roomNumber=0
 	

	 
	return roomList[roomNumber]

# Called when the node enters the scene tree for the first time.
func _ready():	
	

	
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
	
	
	
	#---------
	
	player.global_position.x=600
	player.global_position.y=0
	
	sheep.global_position.x=-10
	sheep.global_position.y=0
	
	
func on_enemy_die(enemy):
	score+=enemy.get_points()
	hud.set_score(score)
	
func on_player_water_changed(new_value):
	hud.set_water(new_value)
