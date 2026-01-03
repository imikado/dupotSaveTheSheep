extends Node2D

var _scoreValue=0
@onready var _scoreLabel:Label=$VBoxContainer/HBoxContainer/scoreLabel

# Called when the node enters the scene tree for the first time.
func _ready():
	print('save')
	GlobalGame.saveHighScore(GlobalPlayer.get_score())
	set_score(GlobalPlayer.get_score())
	
	GlobalGame.saveHighScore(GlobalPlayer.get_score())


func set_score(newScore:int):
	var tween = create_tween()
	tween.tween_method(set_score_text, _scoreValue,newScore, 1)
	_scoreValue=newScore


func set_score_text(scoreValue:int):
	_scoreLabel.text=str(scoreValue)


func _on_label_button_pressed():
	get_tree().change_scene_to_file('res://src/UI/Screens/Menu.tscn')
	pass # Replace with function body.
