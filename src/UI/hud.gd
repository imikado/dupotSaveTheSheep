extends CanvasLayer

const THEME = preload("res://src/UI/Theme.tres")
const PLAYER2_ICON = preload("res://src/UI/Controls/Shared/icon-player2.png")
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
var _resume_button: Button
const MENU_SCENE = "res://src/UI/Screens/Menu.tscn"

# Two players mode: second life row under the one of player 1
const PLAYER2_ROW_SHIFT = 17
const PLAYER_TAG_WIDTH = 16
var _player2Row: Control = null
var _player2ProgressBar: PixelBar = null
var _player2LifeIcon: TextureRect = null


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
	if is_paused and _resume_button != null:
		_resume_button.grab_focus()
	GlobalAudio.play_sfx("pause")
	GlobalAudio.duck_music(is_paused)

# Space / Enter on RESUME are also jump / shoot: resume a bit later so the
# game does not take the key press
func _resume_from_button():
	get_tree().create_timer(0.1, true).timeout.connect(func():
		if get_tree().paused:
			toggle_pause())

# Pause screen: leave the game for the main menu (the game stays frozen
# during the fade, the transition unpauses it)
func quit_to_menu():
	GlobalAudio.duck_music(false)
	GlobalInput.set_two_players(false)
	GlobalTransition.change_scene_to_packed(load(MENU_SCENE))

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
	hint.text = "TAP II TO RESUME" if GlobalInput.is_touch_mode() else "ESC TO RESUME"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(hint)

	var sound = Label.new()
	sound.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sound.add_theme_color_override("font_color", Color(0.627451, 0.647059, 0.960784))
	box.add_child(sound)
	_update_sound_label(GlobalAudio.is_sound_enabled(), sound)
	GlobalAudio.sound_toggled.connect(_update_sound_label.bind(sound))

	# One under the other: up / down still work in two players mode, where
	# the left / right arrows belong to player 2
	var buttons = VBoxContainer.new()
	buttons.add_theme_constant_override("separation", 3)
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 4)
	box.add_child(spacer)
	box.add_child(buttons)
	_resume_button = _pause_button("RESUME", _resume_from_button)
	buttons.add_child(_resume_button)
	buttons.add_child(_pause_button("MENU", quit_to_menu))

	# blink the hint while paused
	var tween = hint.create_tween().set_loops()
	tween.tween_property(hint, "modulate:a", 0.2, 0.0).set_delay(0.6)
	tween.tween_property(hint, "modulate:a", 1.0, 0.0).set_delay(0.4)

func _pause_button(text: String, callback: Callable) -> Button:
	var button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(80, 20)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.pressed.connect(callback)
	return button

func _update_sound_label(enabled: bool, label: Label):
	label.text = "M  SOUND " + ("ON" if enabled else "OFF")
	
func _process(_delta: float):
	if !levelProgression.visible or max_x == 0:
		return
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

func set_player_life(value, index := 1):
	if index == 2:
		if _player2Row != null:
			_update_life_row(_player2Row, _player2ProgressBar, _player2LifeIcon, value)
		return
	_update_life_row($Player, _playerProgressBar, _playerLifeIcon, value)
	_playerLifeValue = value

# Life row of player 2, rows below it go down, "P1" / "P2" tags in the
# colors of the players
func enable_second_player():
	if _player2Row != null:
		return
	_playerProgressBar.size.x -= PLAYER_TAG_WIDTH
	_player2Row = $Player.duplicate()
	_player2Row.name = "Player2"
	add_child(_player2Row)
	move_child(_player2Row, $Player.get_index() + 1)
	_player2Row.position.y += PLAYER2_ROW_SHIFT
	_player2ProgressBar = _player2Row.get_node("lifeBar")
	_player2LifeIcon = _player2Row.get_node("icon")
	_player2LifeIcon.texture = PLAYER2_ICON
	for node in [$Sheep, $Water, key]:
		node.position.y += PLAYER2_ROW_SHIFT
	$StatsPanel.size.y += PLAYER2_ROW_SHIFT
	_add_player_tag($Player, 1)
	_add_player_tag(_player2Row, 2)

func _add_player_tag(row: Control, index: int):
	var bar: Control = row.get_node("lifeBar")
	var tag = Label.new()
	tag.text = "P" + str(index)
	tag.theme = THEME
	tag.add_theme_color_override("font_color", Player.COOP_COLORS[index])
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tag.position = Vector2(bar.position.x + bar.size.x + 1, 0)
	tag.size = Vector2(PLAYER_TAG_WIDTH, row.size.y)
	row.add_child(tag)

# Big message in the middle of the screen (e.g. a player down)
func show_banner(title: String, subtitle: String, color: Color):
	var box = VBoxContainer.new()
	box.theme = THEME
	box.add_theme_constant_override("separation", 0)
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.position.y = 70
	add_child(box)
	for text in [title, subtitle]:
		var label = Label.new()
		label.text = text
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_outline_color", Color.BLACK)
		label.add_theme_constant_override("outline_size", 4)
		box.add_child(label)
	box.get_child(0).add_theme_font_size_override("font_size", 16)
	box.get_child(0).add_theme_color_override("font_color", color)
	var tween = box.create_tween()
	tween.tween_interval(1.6)
	tween.tween_property(box, "modulate:a", 0.0, 0.4)
	tween.tween_callback(box.queue_free)

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
