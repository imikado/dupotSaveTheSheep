extends Area2D

var life=10
 

func _on_body_entered(body):
	if body is Player:
		Fx.sparkle(get_parent(), global_position, Fx.COLOR_HEAL)
		Fx.popup_text(get_parent(), global_position + Vector2(0, -12), "+" + str(life), Color(0.5, 1.0, 0.5))
		body.take_burger(life)
		queue_free()
	pass # Replace with function body.
