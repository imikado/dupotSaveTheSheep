extends CanvasLayer

const THEME = preload("res://src/UI/Theme.tres")
const HURT_COLOR = Color(1, 0.3, 0.3)
const SCORE_COLOR = Color(1, 0.839216, 0.360784)

@export var player: Player
@export var sheep: Sheep

@onready var _scoreLabel: Label = $scorePanel/scoreLabel

@onready var _playerProgressBar: PixelBar = $Player/lifeBar
@onready var _sheepProgressBar: PixelBar = $Sheep/lifeBar
@onready var _waterProgressBar: PixelBar = $Water/lifeBar

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
	_shake_row($Water, _waterLifeIcon, Color.RED)

# Pixel shake of a gauge row, icon flashes with the given color
func _shake_row(row: Control, icon: TextureRect, flash_color: Color):
	if row.has_meta("shaking"):
		return
	row.set_meta("shaking", true)
	var start_x = row.position.x
	var tween = create_tween()
	tween.tween_property(icon, "modulate", flash_color, 0.05)
	for offset in [3, -3, 2, -2, 1, 0]:
		tween.tween_property(row, "position:x", start_x + offset, 0.04)
	tween.tween_property(icon, "modulate", Color.WHITE, 0.2)
	tween.tween_callback(row.remove_meta.bind("shaking"))

# Small hop of the icon when a gauge is refilled
func _bump_icon(icon: TextureRect, flash_color: Color):
	var tween = create_tween()
	tween.tween_property(icon, "modulate", flash_color, 0.05)
	tween.tween_property(icon, "position:y", -2, 0.08)
	tween.tween_property(icon, "position:y", 0, 0.08)
	tween.tween_property(icon, "modulate", Color.WHITE, 0.2)
	
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

func _create_pause_overlay():
	_pause_overlay = ColorRect.new()
	_pause_overlay.name = "PauseOverlay"
	_pause_overlay.theme = THEME
	_pause_overlay.color = Color(0.0, 0.0, 0.06, 0.6)
	_pause_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pause_overlay.visible = false
	add_child(_pause_overlay)

	var panel = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.custom_minimum_size = Vector2(120, 0)
	_pause_overlay.add_child(panel)

	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	panel.add_child(box)

	var title = Label.new()
	title.name = "PauseLabel"
	title.text = "PAUSE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", SCORE_COLOR)
	box.add_child(title)

	var hint = Label.new()
	hint.text = "ESC TO RESUME"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(hint)

	# blink the hint while paused
	var tween = hint.create_tween().set_loops()
	tween.tween_property(hint, "modulate:a", 0.2, 0.0).set_delay(0.6)
	tween.tween_property(hint, "modulate:a", 1.0, 0.0).set_delay(0.4)
	
func _process(delta: float):
	if player != null:
		_playerProgression.global_position.x = _progressionRelativeX * (player.global_position.x / max_x) + _progressionMinX
	if sheep != null:
		_sheepProgression.global_position.x = _progressionRelativeX * (sheep.global_position.x / max_x) + _progressionMinX
 		

func set_score(newScore: int):
	var tween = create_tween()
	tween.tween_method(set_score_text, _scoreValue, newScore, 1)
	if newScore > _scoreValue:
		var flash = create_tween()
		flash.tween_property(_scoreLabel, "modulate", Color(1.6, 1.6, 1.6), 0.05)
		flash.tween_property(_scoreLabel, "modulate", Color.WHITE, 0.4)
	_scoreValue = newScore

func set_score_text(scoreValue: int):
	_scoreLabel.text = str(scoreValue)

func set_water(value):
	if _waterProgressBar._initialized and value > _waterProgressBar.value:
		_bump_icon(_waterLifeIcon, Color(0.6, 0.85, 1))
	_waterProgressBar.set_value_animated(value)
	_waterValue = value

func set_player_life(value):
	_update_life_row($Player, _playerProgressBar, _playerLifeIcon, value)
	_playerLifeValue = value

func set_sheep_life(value):
	var lost = _update_life_row($Sheep, _sheepProgressBar, _sheepLifeIcon, value)
	if lost:
		var tween2 = create_tween()
		for i in 2:
			tween2.tween_property(_sheepProgression, "modulate", HURT_COLOR, 0.15)
			tween2.tween_property(_sheepProgression, "modulate", Color.WHITE, 0.15)

	_sheepLifeValue = value
	update_sheep_danger()

# Update a life gauge, shake on damage, hop on heal. Returns true on damage
func _update_life_row(row: Control, bar: PixelBar, icon: TextureRect, value) -> bool:
	var previous = bar.value
	var initialized = bar._initialized
	bar.set_value_animated(value)
	if !initialized:
		return false
	if value < previous:
		_shake_row(row, icon, HURT_COLOR)
		return true
	if value > previous:
		_bump_icon(icon, Color(0.6, 1, 0.6))
	return false

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
	key.scale = Vector2(2, 2)
	var tween = create_tween()
	tween.tween_property(key, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
