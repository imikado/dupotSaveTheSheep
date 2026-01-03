extends Control

@onready var _backgroundTexture:TextureRect=$TextureRect
@onready var _scoreLabel:Label=$VBoxContainer/HBoxContainer/scoreLabel


var _nextLevel:String="res://src/Levels/bonus_level_1.tscn"

var _scoreValue=0

# Called when the node enters the scene tree for the first time.
func _ready():
	_backgroundTexture.texture=GlobalGame.get_last_screenshot()
	set_score(GlobalPlayer.get_score())


func set_score(newScore:int):
	var tween = create_tween()
	tween.tween_method(set_score_text, _scoreValue,newScore, 1)
	_scoreValue=newScore
	
	GlobalGame.saveHighScore(newScore)


func set_score_text(scoreValue:int):
	_scoreLabel.text=str(scoreValue)


func _on_play_button_pressed():
	get_tree().change_scene_to_file(_nextLevel)
	#GlobalTransition.load
	
