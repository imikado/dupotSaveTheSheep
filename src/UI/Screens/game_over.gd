extends Node2D

const COLOR_GOLD = Color(1, 0.839216, 0.360784)
const COLOR_TEXT = Color(0.92549, 0.937255, 1)
const COUNT_TIME = 1.0

var _scoreValue=0
@onready var _title:Label=$Title
@onready var _scorePanel:PanelContainer=$scorePanel
@onready var _scoreLabel:Label=$scorePanel/VBoxContainer/score/scoreLabel
@onready var _bestLabel:Label=$scorePanel/VBoxContainer/best/bestLabel
@onready var _rankLabel:Label=$scorePanel/VBoxContainer/rank/rankLabel
@onready var _recordLabel:Label=$recordLabel

@onready var _menuButton:Button=$Buttons/menuButton
@onready var _replayButton:Button=$Buttons/replayButton

# Called when the node enters the scene tree for the first time.
func _ready():
	var score = GlobalPlayer.get_score()
	var previousBest = GlobalGame.getHighestScore(GlobalGame.getHighScoreList())
	GlobalGame.saveHighScore(score)
	_bestLabel.text = str(int(max(previousBest, score)))
	_show_rank(score)

	GlobalAudio.play_jingle("game_over")

	_replayButton.visible=false

	if GlobalGame.getLevel() ==2:
		_replayButton.visible=true

	var isRecord = score > previousBest and score > 0
	if isRecord:
		_bestLabel.add_theme_color_override("font_color", COLOR_GOLD)

	_animate(score, isRecord)


# Place of this game in the high score table, "-" when it did not make it
func _show_rank(score: int):
	var rank = 0
	var scoreList = GlobalGame.getHighScoreList()
	for i in scoreList.size():
		var entry = scoreList[i]
		var sameRun = GlobalGame._run_id != "" and entry.get("run", "") == GlobalGame._run_id
		if sameRun or (GlobalGame._run_id == "" and int(entry.score) == score):
			rank = i + 1
			break
	_rankLabel.text = "#" + str(rank) if rank > 0 and score > 0 else "-"
	if rank > 0 and rank <= 3 and score > 0:
		_rankLabel.add_theme_color_override("font_color", COLOR_GOLD)


# Title falls and bounces, then the panel shows up and the score counts up.
# Focus comes after the title so a held key does not skip the screen.
func _animate(score: int, isRecord: bool):
	var target_y = _title.position.y
	_title.position.y = target_y - 60
	_scorePanel.modulate.a = 0.0
	var panel_y = _scorePanel.position.y
	_scorePanel.position.y = panel_y + 8

	var tween = create_tween()
	tween.tween_property(_title, "position:y", target_y, 0.6).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_menuButton.grab_focus)
	tween.tween_property(_scorePanel, "modulate:a", 1.0, 0.2)
	tween.parallel().tween_property(_scorePanel, "position:y", panel_y, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_method(set_score_text, 0, score, COUNT_TIME)
	if isRecord:
		tween.tween_callback(_show_record)
	_scoreValue = score


# Stamp on the score panel: pops in, then pulses
func _show_record():
	_recordLabel.visible = true
	_recordLabel.scale = Vector2(2, 2)
	_recordLabel.modulate.a = 0.0
	var tween = _recordLabel.create_tween()
	tween.tween_property(_recordLabel, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(_recordLabel, "modulate:a", 1.0, 0.1)
	tween.tween_callback(Fx.flash.bind(_scoreLabel, Color(1.8, 1.8, 1.8)))
	var pulse = _recordLabel.create_tween().set_loops()
	pulse.tween_interval(0.3)
	pulse.tween_property(_recordLabel, "scale", Vector2(1.1, 1.1), 0.3).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(_recordLabel, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_SINE)


func set_score_text(scoreValue:int):
	_scoreLabel.text=str(scoreValue)


func _on_label_button_pressed():
	GlobalTransition.change_scene_to_packed(load('res://src/UI/Screens/Menu.tscn'))


func _on_replay_button_pressed() -> void:
	GlobalPlayer.update_life(GlobalGame.getLevelPlayerLife())
	GlobalPlayer.set_water(GlobalGame.getLevelWaterValue())
	GlobalSheep.update_life(GlobalGame.getLevelSheepLife())
	GlobalPlayer.save_score(GlobalGame.getLevelScore())
	GlobalTransition.change_scene_to_packed(load("res://src/Levels/level_2.tscn"))
