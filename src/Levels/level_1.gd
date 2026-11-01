extends LevelBase

@onready var _rooms: Node2D = $SubViewportContainer/SubViewport/rooms
@onready var _sky: ColorRect = $SubViewportContainer/SubViewport/Player/Camera2D/ParallaxBackground/sky/ColorRect

var score: int = 0

var roomNumber = -1

@onready var roomList: Array[Variant] = [Room1, Room2, Room3]

var debugN = 3

var alt = 0

var max_room = 9

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

# Called when the node enters the scene tree for the first time.
func _ready():
	super._ready()

	GlobalEvents.sheep_is_visible.connect(on_sheep_change_visibility)

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

	#player.global_position.x += 760
	#sheep.global_position.x += 740

	debug_hook(currentX)

func _process(delta: float) -> void:
	super._process(delta)
	# The moon rises with the buildings when the camera goes down
	_sky.material.set_shader_parameter("camera_y", -subviewPortMain.canvas_transform.origin.y)

func on_sheep_change_visibility(value):
	pass
