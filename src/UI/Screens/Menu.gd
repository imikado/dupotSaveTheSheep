extends Control

@export var mainLevel: PackedScene

func _ready():
	$AnimatedSprite2D.play()
	$AnimatedSprite2D2.play()
	%PlayButton.grab_focus()
	%levelDifficulty.get_popup().theme_type_variation = &"BigPopup"
	$VersionLabel.text = "v" + ProjectSettings.get_setting("application/config/version", "")
	GlobalAudio.play_music("menu")

	# Menus with every pad, the players get their pad in the level
	GlobalInput.set_two_players(false)

	# Keep the difficulty chosen before the last game
	%levelDifficulty.selected = GlobalGame.getLevelDifficulty()


# 1 PLAYER / 2 PLAYERS: the keys of the players, then START (touch controls
# in one player mode need no keys screen)
var _controls: ControlsScreen = null

func _on_play_button_pressed():
	if GlobalInput.is_touch_mode():
		start_game(false)
		return
	show_controls(false)


func _on_two_players_button_pressed():
	show_controls(true)


func show_controls(two_players: bool):
	if _controls != null:
		return
	# The test players of the screen read the actions of the mode
	GlobalGame.set_two_players(two_players)
	GlobalInput.set_two_players(two_players)
	_controls = ControlsScreen.new(two_players)
	_controls.start_pressed.connect(start_game.bind(two_players))
	_controls.back_pressed.connect(hide_controls.bind(two_players))
	add_child(_controls)


func hide_controls(two_players: bool):
	if _controls == null:
		return
	_controls.queue_free()
	_controls = null
	GlobalGame.set_two_players(false)
	GlobalInput.set_two_players(false)
	(%TwoPlayersButton if two_players else %PlayButton).grab_focus()


func start_game(two_players: bool):
	GlobalGame.resetGame()
	GlobalGame._is_debug = false
	GlobalGame.set_two_players(two_players)
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
