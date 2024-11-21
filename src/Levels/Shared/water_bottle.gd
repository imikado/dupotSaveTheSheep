extends Area2D

@export var _water_value=20*GlobalGame.player_coef_water


# Called when the node enters the scene tree for the first time.
func _ready():
	$AnimatedSprite2D.play()
	pass # Replace with function body.

func _on_body_entered(body):
	if body is Player and body.is_on_floor():
		GlobalPlayer.increment_water(_water_value)
		GlobalEvents.emit_signal("player_take_water_bottle",GlobalPlayer.get_water())
		queue_free()
		
	elif body is PlayerOnMotorBike:
		GlobalPlayer.increment_water(_water_value)
		GlobalEvents.emit_signal("player_take_water_bottle",GlobalPlayer.get_water())
		queue_free()
		
		
	pass # Replace with function body.
