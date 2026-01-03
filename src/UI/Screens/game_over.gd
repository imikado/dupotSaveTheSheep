extends Node2D

var _scoreValue=0
@onready var _scoreLabel:Label=$VBoxContainer/HBoxContainer/scoreLabel

@onready var _replayButton:TextureButton=$replayButton

# Called when the node enters the scene tree for the first time.
func _ready():
	print('save')
	GlobalGame.saveHighScore(GlobalPlayer.get_score())
	set_score(GlobalPlayer.get_score())
	
	GlobalGame.saveHighScore(GlobalPlayer.get_score())
	
	_replayButton.visible=false
	
	if GlobalGame.getLevel() ==2:
		_replayButton.visible=true


func set_score(newScore:int):
	var tween = create_tween()
	tween.tween_method(set_score_text, _scoreValue,newScore, 1)
	_scoreValue=newScore


func set_score_text(scoreValue:int):
	_scoreLabel.text=str(scoreValue)


func _on_label_button_pressed():
	get_tree().change_scene_to_file('res://src/UI/Screens/Menu.tscn')
	pass # Replace with function body.


func _on_replay_button_pressed() -> void:
	GlobalPlayer._life=GlobalGame.getLevelPlayerLife()
	GlobalPlayer._water=GlobalGame.getLevelWaterValue()
	GlobalSheep._life=GlobalGame.getLevelSheepLife()
	GlobalPlayer.save_score(GlobalGame.getLevelScore())
	get_tree().change_scene_to_file("res://src/Levels/level_2.tscn")
	pass # Replace with function body.
