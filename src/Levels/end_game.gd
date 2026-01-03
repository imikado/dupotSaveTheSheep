extends Control

@onready var _backgroundTexture:TextureRect=$TextureRect

@onready var _userScoreLabel = $VBoxContainer2/userScoreLabel
@onready var _bonusUserScoreLabel = $VBoxContainer2/bonusUserScoreLabel
@onready var _bonusSheepScoreLabel = $VBoxContainer2/bonusSheepScoreLabel
@onready var _bonusLevelScoreLabel = $VBoxContainer2/bonusLevelScoreLabel

@onready var _totalScoreLabel:Label= $VBoxContainer2/totalScoreLabel

@export var NextLevel: PackedScene

var _scoreValue=0

# Called when the node enters the scene tree for the first time.
func _ready():
	_backgroundTexture.texture=GlobalGame.get_last_screenshot()
	
	var userScore = GlobalPlayer.get_score()
	
	var bonusLevelScore:=0
	var bonusLife:=0
	var bonusPlayerLife:=0
	var bonusSheepLife:=0
	
	if GlobalGame.isLevelDifficultyEasy():
		bonusLevelScore=100
		bonusLife=1
	else:
		bonusLevelScore=500
		bonusLife=2
		
	bonusPlayerLife=GlobalPlayer.get_life()*bonusLife
	bonusSheepLife=GlobalSheep.get_life()*bonusLife
	
	_userScoreLabel.text='User score: '+str(GlobalPlayer.get_score())
	_bonusLevelScoreLabel.text='Bonus Level completed: +'+str(bonusLevelScore)
	_bonusUserScoreLabel.text='Bonus player life: +'+str(bonusPlayerLife)
	_bonusUserScoreLabel.text+=' ('+str(GlobalPlayer.get_life())+'x'+str(bonusLife)+')'
	_bonusSheepScoreLabel.text='Bonus sheep life: +'+str(bonusSheepLife)
	_bonusSheepScoreLabel.text+=' ('+str(GlobalSheep.get_life())+'x'+str(bonusLife)+')'
	
	var totalScore=0
	totalScore+=userScore
	totalScore+=bonusLevelScore
	totalScore+=bonusPlayerLife
	totalScore+=bonusSheepLife
	
	GlobalPlayer.save_score(totalScore)
			
	set_score(totalScore)


func set_score(newScore:int):
	var tween = create_tween()
	tween.tween_method(set_score_text, _scoreValue,newScore, 1)
	_scoreValue=newScore
	
	GlobalGame.saveHighScore(newScore)


func set_score_text(scoreValue:int):
	_totalScoreLabel.text=str(scoreValue)


func _on_play_button_pressed():
	GlobalTransition.change_scene_to_packed(NextLevel)
	#GlobalTransition.load
	
