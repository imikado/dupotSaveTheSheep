extends Node2D


func _on_sheep_area_body_entered(body: Node2D) -> void:
	if body is Sheep:
		body.set_process(false)
		body.global_position.x+=20
		body.global_position.y-=2
		body.set_process(true)
		
	pass # Replace with function body.
