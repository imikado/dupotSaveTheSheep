extends Area2D

var life=10
 

func _on_body_entered(body):
	if body is Player:
		body.take_burger(life)
		queue_free()
	pass # Replace with function body.
