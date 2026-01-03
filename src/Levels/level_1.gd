extends Node2D

@export var NextLevel: PackedScene
@export var gameOverScene: PackedScene

@onready var hud = $HUD

@onready var _rooms: Node2D = $SubViewportContainer/SubViewport/rooms

@onready var player: Player = $SubViewportContainer/SubViewport/Player
@onready var sheep: Sheep = $SubViewportContainer2/SubViewport/Sheep

@onready var subviewPortMain = $SubViewportContainer/SubViewport
@onready var subViewPortSheep = $SubViewportContainer2/SubViewport


var score: int = 0

var roomNumber = -1

@onready var roomList: Array[Variant] = [Room1, Room2, Room3]

var gameover = false

var debugN = 3

var alt = 0

var max_room = 9

const DISTANCE_TO_PLAYER_X = 230
const DISTANCE_TO_PLAYER_Y = 60

func get_room() -> Variant:
	roomNumber += 1
	if roomNumber >= roomList.size():
		roomNumber = 0
 	 
	if roomNumber == 2:
		if alt == 0:
			alt = 1
			return Room4
		else:
			alt = 0
	
	return roomList[roomNumber]

	
func debug_hook(room_end_x: float):
	if GlobalGame.is_debug():
		player.global_position.x += room_end_x
		
		sheep.global_position.x += room_end_x + 100

func _process(_delta: float) -> void:
	if sheep != null and player != null and (abs(sheep.global_position.x - player.global_position.x) > DISTANCE_TO_PLAYER_X or abs(sheep.global_position.y - player.global_position.y) > DISTANCE_TO_PLAYER_Y):
		$SubViewportContainer2.visible = true
		$ColorRect.visible = true
	else:
		$SubViewportContainer2.visible = false
		$ColorRect.visible = false


# Called when the node enters the scene tree for the first time.
func _ready():
	var world = subviewPortMain.find_world_2d()
	subViewPortSheep.world_2d = world
	
	GlobalPlayer.set_actor(player)
	
	GlobalEvents.player_gameover.connect(on_player_gameover)
	
	GlobalEvents.enemy_die.connect(on_enemy_die)

	GlobalEvents.player_take_water_bottle.connect(on_player_take_water_bottle)

	GlobalEvents.player_water_changed.connect(on_player_water_changed)

	GlobalEvents.player_take_damage.connect(on_player_take_damage)

	GlobalEvents.sheep_take_damage.connect(on_sheep_take_damage)

	GlobalEvents.player_increase_life.connect(on_player_increase_life)

	GlobalEvents.end_level.connect(on_end_level)
	
	GlobalEvents.sheep_is_visible.connect(on_sheep_change_visibility)
	

	hud.set_score(GlobalPlayer.get_score())
	hud.set_water(GlobalPlayer.get_water())
	hud.set_player_life(GlobalPlayer.get_life())
	hud.set_sheep_life(GlobalSheep.get_life())

	#rooms
	var currentX = 0
	
	var roomStart: RoomAbstract = RoomStart.create()
	
	_rooms.add_child(roomStart)
	
	roomStart.global_position.x = roomStart.width * -1
	roomStart.global_position.y = 0
	
	var maxRoomNumber = 9
	if GlobalGame.isLevelDifficultyEasy():
		maxRoomNumber = 4
	else:
		maxRoomNumber = 16
	
	for i in range(1, maxRoomNumber):
		var roomLoop = get_room().create()
		
		_rooms.add_child(roomLoop)
		
		roomLoop.global_position.x = currentX
		roomLoop.global_position.y = 0
		
		if i == 1:
			roomLoop.set_decor_visible(true)
	
		currentX += roomLoop.width
	
	var roomEnd: RoomAbstract = RoomEnd.create()
	_rooms.add_child(roomEnd)
	
	roomEnd.global_position.x = currentX
	roomEnd.global_position.y = 0
	
	player.global_position.x += 30
	
	sheep.global_position.x = -20
	
	hud.max_x = currentX + roomEnd.width

	debug_hook(currentX)

func on_sheep_change_visibility(value):
	print('change visibility')
	print(value)
	
func on_enemy_die(enemy):
	GlobalPlayer.increase_score(enemy.get_points())
	hud.set_score(GlobalPlayer.get_score())
	
func on_player_water_changed(new_value):
	hud.set_water(new_value)

func on_player_take_water_bottle(water_value):
	player.take_water(water_value)

func on_player_take_damage(damage):
	GlobalPlayer.decrease_life(damage)
	hud.set_player_life(GlobalPlayer.get_life())
	if GlobalPlayer.get_life() <= 0:
		on_player_gameover()


func on_player_increase_life(value):
	GlobalPlayer.increase_life(value)
	hud.set_player_life(GlobalPlayer.get_life())
	

func on_sheep_take_damage(damage):
	GlobalSheep.decrease_life(damage)
	hud.set_sheep_life(GlobalSheep.get_life())
	if GlobalSheep.get_life() <= 0:
		on_player_gameover()

func on_player_gameover():
	if !gameover:
		print("game over level")
		gameover = true
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
