extends Control

@export var MainLevel:PackedScene


func _on_play_button_pressed():
	GlobalGame.resetGame()
	GlobalTransition.change_scene_to_packed(MainLevel)
	pass # Replace with function body.
