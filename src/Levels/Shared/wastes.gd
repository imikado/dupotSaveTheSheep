extends Area2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_body_entered(body):
	print(body)
	if body is Player:
		print('gameover')
		get_tree().change_scene_to_file('res://src/UI/Screens/game_over.tscn')
	pass # Replace with function body.