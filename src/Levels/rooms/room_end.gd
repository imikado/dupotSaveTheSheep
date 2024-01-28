extends RoomAbstract


func _on_area_2d_body_entered(body):
	if body is motorbike_endlevel:
		GlobalEvents.end_level.emit()

