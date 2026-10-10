extends Control

@export var mainLevel: PackedScene

func _ready():
	$AnimatedSprite2D.play()
	$AnimatedSprite2D2.play()
	$PlayButton.grab_focus()
	$VersionLabel.text = "v" + ProjectSettings.get_setting("application/config/version", "")
	GlobalAudio.play_music("menu")

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


func _on_score_button_pressed() -> void:
	GlobalTransition.change_scene_to_packed(load("res://src/UI/Screens/scores.tscn"))
	pass # Replace with function body.
