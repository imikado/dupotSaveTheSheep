extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	print('save')
	GlobalGame.saveHighScore(GlobalPlayer.get_score())

	pass # Replace with function body.




func _on_label_button_pressed():
	get_tree().change_scene_to_file('res://src/UI/Screens/Menu.tscn')
	pass # Replace with function body.
