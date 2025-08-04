extends Control

@export var mainLevel: PackedScene

func _ready():
	$AnimatedSprite2D.play()
	$AnimatedSprite2D2.play()

	GlobalGame.loadDifficulty(GlobalGame.LEVEL_DIFFICULTY.NORMAL)

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
	GlobalTransition.change_scene_to_packed(mainLevel)


func _on_level_difficulty_item_selected(index: int) -> void:
	GlobalGame.loadDifficulty(index)
