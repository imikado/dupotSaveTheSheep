extends RoomAbstract


func _on_area_2d_body_entered(body):
	if body is motorbike_endlevel:
		body.set_process(false)
		GlobalEvents.end_level.emit()
