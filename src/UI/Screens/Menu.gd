extends Control

@export var MainLevelPlayerCamera:PackedScene
@export var MainLevelZoomedCamera:PackedScene

func _ready():
	$AnimatedSprite2D.play()
	$AnimatedSprite2D2.play()

func _on_play_button_pressed():
	GlobalGame.resetGame()
	GlobalGame._is_debug=false
	launch_level()
	pass # Replace with function body.


func _on_play_button_2_pressed():
	
	GlobalGame.resetGame()
	GlobalGame._is_debug=true
	launch_level()
	pass # Replace with function body.

func launch_level():
	if GlobalGame.isPlayerCameraMode():
		GlobalTransition.change_scene_to_packed(MainLevelPlayerCamera)
	else:
		GlobalTransition.change_scene_to_packed(MainLevelZoomedCamera)


func _on_camera_mode_item_selected(index: int) -> void:
	GlobalGame.camera_mode=index
	pass # Replace with function body.
