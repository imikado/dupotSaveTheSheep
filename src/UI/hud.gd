extends CanvasLayer

@export var player: Player
@export var sheep: Sheep

@onready var _scoreLabel: Label = $scoreLabel

@onready var _playerProgressBar: ProgressBar = $Player/lifeBar
@onready var _sheepProgressBar: ProgressBar = $Sheep/lifeBar
@onready var _waterProgressBar: ProgressBar = $Water/lifeBar

@onready var _playerLifeColorRect: ColorRect = $Player/ColorRect
@onready var _sheepLifeColorRect: ColorRect = $Sheep/ColorRect
@onready var _waterColorRect: ColorRect = $Water/ColorRect

@onready var _playerLifeIcon: TextureRect = $Player/icon
@onready var _sheepLifeIcon: TextureRect = $Sheep/icon
@onready var _waterLifeIcon: TextureRect = $Water/icon

@onready var _minPosition: Marker2D = $LevelProgression/Marker2D
@onready var _maxPosition: Marker2D = $LevelProgression/Marker2D2

@onready var _playerProgression: TextureRect = $LevelProgression/player
@onready var _sheepProgression: TextureRect = $LevelProgression/sheep

@onready var levelProgression = $LevelProgression

@onready var key= $Items/keyIcon

var min_x = 0
var max_x = 0

var _scoreValue = 0
var _playerLifeValue = 0
var _sheepLifeValue = 0
var _waterValue = 0


@onready var _progressionMinX: float = $LevelProgression/Marker2D.global_position.x
@onready var _progressionMaX: float = $LevelProgression/Marker2D2.global_position.x

@onready var _progressionRelativeX = _progressionMaX - _progressionMinX

# Called when the node enters the scene tree for the first time.
func _ready():
	key.visible=false
	pass # Replace with function body.
	
func disableProgression():
	levelProgression.visible=false
	
func _process(delta: float):
	if player != null:
		_playerProgression.global_position.x = _progressionRelativeX * (player.global_position.x / max_x) + _progressionMinX
	if sheep != null:
		_sheepProgression.global_position.x = _progressionRelativeX * (sheep.global_position.x / max_x) + _progressionMinX
 		

func set_score(newScore: int):
	#var tween=create_tween()
	#tween.tween_property(scoreLabel,"text",newscore,0.9).set_trans(Tween.TRANS_LINEAR)
	var tween = create_tween()
	tween.tween_method(set_score_text, _scoreValue, newScore, 1)
	_scoreValue = newScore

func set_score_text(scoreValue: int):
	_scoreLabel.text = str(scoreValue)

func set_water(value):
	var tween = create_tween().set_parallel(true)
	tween.tween_property(_waterColorRect, "modulate", Color.BLUE, 0.5)
	tween.tween_property(_waterLifeIcon, "modulate", Color.BLUE, 0.5)
	tween.tween_property(_waterProgressBar, "value", value, 0.9).set_trans(Tween.TRANS_LINEAR)
	
	tween.chain().tween_property(_waterColorRect, "modulate", Color.WHITE, 0.3)
	tween.chain().tween_property(_waterLifeIcon, "modulate", Color.WHITE, 0.3)

	#waterProgressBar.value=value
	_waterValue = value

func set_player_life(value):
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(_playerLifeColorRect, "modulate", Color.RED, 0.5)
	tween.tween_property(_playerLifeIcon, "modulate", Color.RED, 0.5)
	tween.tween_property(_playerProgressBar, "value", value, 0.9).set_trans(Tween.TRANS_LINEAR)

	tween.chain().tween_property(_playerLifeColorRect, "modulate", Color.WHITE, 0.3)
	tween.chain().tween_property(_playerLifeIcon, "modulate", Color.WHITE, 0.3)

	_playerLifeValue = value
	

func set_sheep_life(value):
	var tween = create_tween().set_parallel(true)
	tween.tween_property(_sheepLifeColorRect, "modulate", Color.RED, 0.5)
	tween.tween_property(_sheepLifeIcon, "modulate", Color.RED, 0.5)
	tween.tween_property(_sheepProgressBar, "value", value, 0.3).set_trans(Tween.TRANS_LINEAR)

	tween.chain().tween_property(_sheepLifeColorRect, "modulate", Color.WHITE, 0.3)
	tween.chain().tween_property(_sheepLifeIcon, "modulate", Color.WHITE, 0.3)

	var tween2 = create_tween().set_parallel(true)
	tween2.tween_property(_sheepProgression, "modulate", Color.RED, 0.5)
	tween2.chain().tween_property(_sheepProgression, "modulate", Color.WHITE, 0.3)
	tween2.tween_property(_sheepProgression, "modulate", Color.RED, 0.5)
	tween2.chain().tween_property(_sheepProgression, "modulate", Color.WHITE, 0.3)

	_sheepLifeValue = value

func enable_key():
	key.visible=true
