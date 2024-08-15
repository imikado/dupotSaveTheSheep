extends Control

@export var MainLevel:PackedScene


func _ready():
	$AnimatedSprite2D.play()
	$AnimatedSprite2D2.play()

func _on_play_button_pressed():
	GlobalGame.resetGame()
	GlobalGame._is_debug=false
	GlobalTransition.change_scene_to_packed(MainLevel)
	pass # Replace with function body.


func _on_play_button_2_pressed():
	
	GlobalGame.resetGame()
	GlobalGame._is_debug=true
	GlobalTransition.change_scene_to_packed(MainLevel)
	pass # Replace with function body.
