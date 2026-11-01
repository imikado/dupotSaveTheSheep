extends Control

@export var mainLevel: PackedScene

func _ready():
	$AnimatedSprite2D.play()
	$AnimatedSprite2D2.play()
	%PlayButton.grab_focus()
	%levelDifficulty.get_popup().theme_type_variation = &"BigPopup"
	$VersionLabel.text = "v" + ProjectSettings.get_setting("application/config/version", "")
	GlobalAudio.play_music("menu")

	# Keep the difficulty chosen before the last game
	%levelDifficulty.selected = GlobalGame.getLevelDifficulty()

	# No keyboard help when playing with touch controls
	GlobalInput.touch_mode_changed.connect(_on_touch_mode_changed)
	_on_touch_mode_changed(GlobalInput.is_touch_mode())

func _on_touch_mode_changed(enabled: bool):
	%KeysPanel.visible = !enabled

func _on_play_button_pressed():
	GlobalGame.resetGame()
	GlobalGame._is_debug = false
	launch_level()


func _on_play_button_2_pressed():
	GlobalGame.resetGame()
	GlobalGame._is_debug = true
	launch_level()

func launch_level():
	GlobalTransition.change_scene_to_packed(mainLevel)


func _on_level_difficulty_item_selected(index: int) -> void:
	GlobalGame.loadDifficulty(index)


func _on_score_button_pressed() -> void:
	GlobalTransition.change_scene_to_packed(load("res://src/UI/Screens/scores.tscn"))
