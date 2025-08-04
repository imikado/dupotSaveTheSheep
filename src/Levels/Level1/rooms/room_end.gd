class_name RoomEnd extends RoomAbstract


const SCENE: PackedScene = preload("res://src/Levels/Level1/rooms/room_end.tscn")

static func create() -> RoomEnd:
	var room = SCENE.instantiate()
	return room

func _on_area_2d_body_entered(body):
	if body is motorbike_endlevel:
		body.set_process(false)
		GlobalEvents.end_level.emit()
