extends Area2D

@export var _water_value=20*GlobalGame.player_coef_water

var _taken=false


# Called when the node enters the scene tree for the first time.
func _ready():
	$AnimatedSprite2D.play()

# Jumping into the bottle then landing on it does not fire body_entered again
func _physics_process(_delta):
	for body in get_overlapping_bodies():
		if body is Player:
			_on_body_entered(body)

func _on_body_entered(body):
	if _taken:
		return
	if body is Player and body.is_on_floor():
		_taken=true
		Fx.sparkle(get_parent(), global_position, Fx.COLOR_WATER)
		GlobalAudio.play_sfx("pickup_water")
		GlobalPlayer.increment_water(_water_value)
		body.take_water(GlobalPlayer.get_water())
		queue_free()
		
	elif body is PlayerOnMotorBike:
		_taken=true
		Fx.sparkle(get_parent(), global_position, Fx.COLOR_WATER)
		GlobalAudio.play_sfx("pickup_water")
		GlobalPlayer.increment_water(_water_value)
		body.take_water(GlobalPlayer.get_water())
		queue_free()
		
		
