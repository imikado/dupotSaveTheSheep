extends Area2D

var life=10
 

func _on_body_entered(body):
	if body is PlayerOnMotorBike:
		GlobalAudio.play_sfx("pickup_life")
		Fx.sparkle(get_parent(), global_position, Fx.COLOR_HEAL)
		body.take_desserts(life)
		queue_free()
