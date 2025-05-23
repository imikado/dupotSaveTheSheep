extends Control

@export var MainLevelPlayerCamera: PackedScene

func _ready():
	$AnimatedSprite2D.play()
	$AnimatedSprite2D2.play()

func _on_play_button_pressed():
	GlobalGame.resetGame()
	GlobalGame._is_debug = false
	launch_level()
	pass # Replace with function body.


func _on_play_button_2_pressed():
	GlobalGame.resetGame()
	GlobalGame._is_debug = true
	launch_level()
	pass # Replace with function body.

func launch_level():
	GlobalTransition.change_scene_to_packed(MainLevelPlayerCamera)


func _on_level_difficulty_item_selected(index: int) -> void:
	GlobalGame.loadDifficulty(index)
