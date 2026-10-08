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

var _pause_overlay: ColorRect
var _pause_label: Label


@onready var _progressionMinX: float = $LevelProgression/Marker2D.global_position.x
@onready var _progressionMaX: float = $LevelProgression/Marker2D2.global_position.x

@onready var _progressionRelativeX = _progressionMaX - _progressionMinX

# Called when the node enters the scene tree for the first time.
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	key.visible=false
	GlobalEvents.player_out_of_water.connect(on_player_out_of_water)
	_create_pause_overlay()

# Shake the water gauge so the player understands why nothing is fired
func on_player_out_of_water():
	var water: Control = $Water
	if water.has_meta("shaking"):
		return
	water.set_meta("shaking", true)
	var start_x = water.position.x
	var tween = create_tween()
	tween.tween_property(_waterLifeIcon, "modulate", Color.RED, 0.05)
	for offset in [3, -3, 2, -2, 1, 0]:
		tween.tween_property(water, "position:x", start_x + offset, 0.04)
	tween.tween_property(_waterLifeIcon, "modulate", Color.WHITE, 0.2)
	tween.tween_callback(water.remove_meta.bind("shaking"))
	
func disableProgression():
	levelProgression.visible=false

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func toggle_pause():
	var is_paused = !get_tree().paused
	get_tree().paused = is_paused
	if _pause_overlay != null:
		_pause_overlay.visible = is_paused
	if _pause_label != null:
		_pause_label.visible = is_paused

func _create_pause_overlay():
	_pause_overlay = ColorRect.new()
	_pause_overlay.name = "PauseOverlay"
	_pause_overlay.color = Color(0.0, 0.0, 0.0, 0.58)
	_pause_overlay.anchor_left = 0.0
	_pause_overlay.anchor_top = 0.0
	_pause_overlay.anchor_right = 1.0
	_pause_overlay.anchor_bottom = 1.0
	_pause_overlay.offset_left = 0
	_pause_overlay.offset_top = 0
	_pause_overlay.offset_right = 0
	_pause_overlay.offset_bottom = 0
	_pause_overlay.visible = false
	add_child(_pause_overlay)

	_pause_label = Label.new()
	_pause_label.name = "PauseLabel"
	_pause_label.text = "PAUSE"
	_pause_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pause_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_pause_label.anchor_left = 0.5
	_pause_label.anchor_top = 0.5
	_pause_label.anchor_right = 0.5
	_pause_label.anchor_bottom = 0.5
	_pause_label.offset_left = -80
	_pause_label.offset_top = -18
	_pause_label.offset_right = 80
	_pause_label.offset_bottom = 18
	_pause_label.add_theme_font_size_override("font_size", 28)
	_pause_label.visible = false
	_pause_overlay.add_child(_pause_label)
	
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
	update_sheep_danger()

# Pulse the sheep icon while its life is low
var _sheepDangerTween: Tween = null

func update_sheep_danger():
	var in_danger = _sheepLifeValue > 0 and _sheepLifeValue <= GlobalGame.sheep_start_life * 0.3
	if in_danger and _sheepDangerTween == null:
		_sheepDangerTween = create_tween().set_loops()
		_sheepDangerTween.tween_property(_sheepLifeIcon, "self_modulate", Color(1, 0.3, 0.3), 0.3)
		_sheepDangerTween.tween_property(_sheepLifeIcon, "self_modulate", Color.WHITE, 0.3)
	elif !in_danger and _sheepDangerTween != null:
		_sheepDangerTween.kill()
		_sheepDangerTween = null
		_sheepLifeIcon.self_modulate = Color.WHITE

func enable_key():
	key.visible=true
