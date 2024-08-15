extends Area2D

var life=10
 

func _on_body_entered(body):
	if body is PlayerOnMotorBike:
		body.take_desserts(life)
		queue_free()
	pass # Replace with function body.
