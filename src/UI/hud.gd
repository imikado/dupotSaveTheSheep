extends CanvasLayer

@onready var _scoreLabel:Label=$scoreLabel

@onready var _playerProgressBar:ProgressBar=$Player/lifeBar
@onready var _sheepProgressBar:ProgressBar=$Sheep/lifeBar
@onready var _waterProgressBar:ProgressBar=$Water/lifeBar

@onready var _playerLifeColorRect:ColorRect=$Player/ColorRect
@onready var _sheepLifeColorRect:ColorRect=$Sheep/ColorRect
@onready var _waterColorRect:ColorRect=$Water/ColorRect

@onready var _playerLifeIcon:TextureRect=$Player/icon
@onready var _sheepLifeIcon:TextureRect=$Sheep/icon
@onready var _waterLifeIcon:TextureRect=$Water/icon


var _scoreValue=0
var _playerLifeValue=0
var _sheepLifeValue=0
var _waterValue=0


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func set_score(newScore:int):
	#var tween=create_tween()
	#tween.tween_property(scoreLabel,"text",newscore,0.9).set_trans(Tween.TRANS_LINEAR)
	var tween = create_tween()
	tween.tween_method(set_score_text, _scoreValue,newScore, 1)
	_scoreValue=newScore

func set_score_text(scoreValue:int):
	_scoreLabel.text=str(scoreValue)

func set_water(value):
	var tween=create_tween().set_parallel(true)
	tween.tween_property(_waterColorRect,"modulate",Color.BLUE,0.5)
	tween.tween_property(_waterLifeIcon,"modulate",Color.BLUE,0.5)
	tween.tween_property(_waterProgressBar,"value",value,0.9).set_trans(Tween.TRANS_LINEAR)
	
	tween.chain().tween_property(_waterColorRect,"modulate",Color.WHITE,0.3)
	tween.chain().tween_property(_waterLifeIcon,"modulate",Color.WHITE,0.3)

	#waterProgressBar.value=value
	_waterValue=value

func set_player_life(value):
	var tween=create_tween().set_parallel(true)
	tween.tween_property(_playerLifeColorRect,"modulate",Color.RED,0.5)
	tween.tween_property(_playerLifeIcon,"modulate",Color.RED,0.5)
	tween.tween_property(_playerProgressBar,"value",value,0.9).set_trans(Tween.TRANS_LINEAR)

	tween.chain().tween_property(_playerLifeColorRect,"modulate",Color.WHITE,0.3)
	tween.chain().tween_property(_playerLifeIcon,"modulate",Color.WHITE,0.3)

	
	#playerProgressBar.value=value
	_playerLifeValue=value

func set_sheep_life(value):
	var tween=create_tween().set_parallel(true)
	tween.tween_property(_sheepLifeColorRect,"modulate",Color.RED,0.5)
	tween.tween_property(_sheepLifeIcon,"modulate",Color.RED,0.5)
	tween.tween_property(_sheepProgressBar,"value",value,0.3).set_trans(Tween.TRANS_LINEAR)

	tween.chain().tween_property(_sheepLifeColorRect,"modulate",Color.WHITE,0.3)
	tween.chain().tween_property(_sheepLifeIcon,"modulate",Color.WHITE,0.3)
	#sheepProgressBar.value=value
	_sheepLifeValue=value

