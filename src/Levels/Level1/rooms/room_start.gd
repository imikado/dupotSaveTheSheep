class_name RoomStart extends RoomAbstract


const SCENE: PackedScene = preload("res://src/Levels/Level1/rooms/room_start.tscn")

static func create() -> RoomStart:
	var room = SCENE.instantiate()
	return room