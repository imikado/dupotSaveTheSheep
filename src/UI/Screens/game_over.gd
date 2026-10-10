extends Node2D

var _scoreValue=0
@onready var _scoreLabel:Label=$scorePanel/VBoxContainer/score/scoreLabel
@onready var _bestLabel:Label=$scorePanel/VBoxContainer/best/bestLabel
@onready var _recordLabel:Label=$recordLabel

@onready var _replayButton:TextureButton=$replayButton

# Called when the node enters the scene tree for the first time.
func _ready():
	var score = GlobalPlayer.get_score()
	var previousBest = GlobalGame.getHighestScore(GlobalGame.getHighScoreList())
	GlobalGame.saveHighScore(score)
	set_score(score)
	_bestLabel.text = str(int(max(previousBest, score)))

	GlobalAudio.play_jingle("game_over")

	_replayButton.visible=false
	
	if GlobalGame.getLevel() ==2:
		_replayButton.visible=true

	_animate_title()

	if score > previousBest and score > 0:
		_show_record()


# Blinking stamp on the score panel
func _show_record():
	_recordLabel.visible = true
	var tween = _recordLabel.create_tween().set_loops()
	tween.tween_property(_recordLabel, "modulate:a", 0.2, 0.0).set_delay(0.5)
	tween.tween_property(_recordLabel, "modulate:a", 1.0, 0.0).set_delay(0.3)


# Title falls and bounces, focus comes after so a held key does not skip the screen
func _animate_title():
	var title: Label = $Label
	var target_y = title.position.y
	title.position.y = target_y - 60
	var tween = create_tween()
	tween.tween_property(title, "position:y", target_y, 0.6).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_callback($LabelButton.grab_focus)


func set_score(newScore:int):
	var tween = create_tween()
	tween.tween_method(set_score_text, _scoreValue,newScore, 1)
	_scoreValue=newScore


func set_score_text(scoreValue:int):
	_scoreLabel.text=str(scoreValue)


func _on_label_button_pressed():
	GlobalTransition.change_scene_to_packed(load('res://src/UI/Screens/Menu.tscn'))
	pass # Replace with function body.


func _on_replay_button_pressed() -> void:
	GlobalPlayer._life=GlobalGame.getLevelPlayerLife()
	GlobalPlayer._water=GlobalGame.getLevelWaterValue()
	GlobalSheep._life=GlobalGame.getLevelSheepLife()
	GlobalPlayer.save_score(GlobalGame.getLevelScore())
	get_tree().change_scene_to_file("res://src/Levels/level_2.tscn")
	pass # Replace with function body.
