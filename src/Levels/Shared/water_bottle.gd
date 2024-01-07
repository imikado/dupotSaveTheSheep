extends Area2D


# Called when the node enters the scene tree for the first time.
func _ready():
	$AnimatedSprite2D.play()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


func _on_body_entered(body):
	if body is Player and body.is_on_floor():
		GlobalPlayer.increment_water(10)
		GlobalEvents.emit_signal("player_take_water_bottle",GlobalPlayer.get_water())
		queue_free()
	pass # Replace with function body.
