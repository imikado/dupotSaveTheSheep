extends Control
class_name LevelResult

# Score summary shown at the end of a level: the bonus lines appear one by one,
# then the total counts up and the button shows up.

const COLOR_GOLD = Color(1, 0.839216, 0.360784)
const COLOR_TEXT = Color(0.92549, 0.937255, 1)
const COLOR_DIM = Color(0.627451, 0.647059, 0.960784)
const COLOR_GAIN = Color(0.5, 1, 0.5)

const ICON_PLAYER = preload("res://src/UI/Controls/Shared/icon-player.png")
const ICON_SHEEP = preload("res://src/UI/Controls/Shared/icon-sheep.png")
const ICON_KEY = preload("res://src/UI/Controls/Shared/icon-key.png")
const ICON_SPIDER = preload("res://src/UI/Controls/Shared/icon-spider.png")

const ROW_DELAY = 0.3
const COUNT_TIME = 1.0

@export_file("*.tscn") var next_scene_path: String

@onready var _background: TextureRect = $Background
@onready var _title: Label = $Title
@onready var _panel: PanelContainer = $Panel
@onready var _rows: VBoxContainer = $Panel/Content/Rows
@onready var _totalRow: Control = $Panel/Content/Total
@onready var _totalLabel: Label = $Panel/Content/Total/Value
@onready var _nextButton: TextureButton = $NextButton

var _scoreValue = 0


func _ready():
	_background.texture = GlobalGame.get_last_screenshot()

	var userScore = GlobalPlayer.get_score()

	var bonusLevelScore := 0
	var bonusLife := 0

	if GlobalGame.isLevelDifficultyEasy():
		bonusLevelScore = 100
		bonusLife = 1
	else:
		bonusLevelScore = 500
		bonusLife = 2

	var bonusPlayerLife = GlobalPlayer.get_life() * bonusLife
	var bonusSheepLife = GlobalSheep.get_life() * bonusLife

	_add_row(ICON_SPIDER, "SCORE", str(userScore), COLOR_TEXT)
	_add_row(ICON_PLAYER, "GORDON %sx%s" % [GlobalPlayer.get_life(), bonusLife], "+" + str(bonusPlayerLife))
	_add_row(ICON_SHEEP, "SHEEP %sx%s" % [GlobalSheep.get_life(), bonusLife], "+" + str(bonusSheepLife))
	_add_row(ICON_KEY, "LEVEL CLEAR", "+" + str(bonusLevelScore))

	var totalScore = userScore + bonusLevelScore + bonusPlayerLife + bonusSheepLife

	GlobalPlayer.save_score(totalScore)
	GlobalGame.saveHighScore(totalScore)

	GlobalAudio.play_jingle("level_complete")
	_animate(totalScore)


func _add_row(icon: Texture2D, text: String, value: String, value_color := COLOR_GAIN) -> void:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)

	var iconRect = TextureRect.new()
	iconRect.texture = icon
	iconRect.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	iconRect.custom_minimum_size = Vector2(16, 16)
	row.add_child(iconRect)

	var label = Label.new()
	label.text = text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_color_override("font_color", COLOR_DIM)
	row.add_child(label)

	var valueLabel = Label.new()
	valueLabel.text = value
	valueLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	valueLabel.add_theme_color_override("font_color", value_color)
	row.add_child(valueLabel)

	row.modulate.a = 0.0
	_rows.add_child(row)


func _animate(totalScore: int) -> void:
	_nextButton.visible = false
	_totalRow.modulate.a = 0.0
	_totalLabel.text = "0"

	# title falls and bounces
	var target_y = _title.position.y
	_title.position.y = target_y - 50
	var tween = create_tween()
	tween.tween_property(_title, "position:y", target_y, 0.6).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

	# rows pop one after the other
	for row in _rows.get_children():
		tween.tween_interval(ROW_DELAY)
		tween.tween_callback(GlobalAudio.play_sfx.bind("tick"))
		tween.tween_property(row, "modulate:a", 1.0, 0.1)

	tween.tween_interval(ROW_DELAY)
	tween.tween_property(_totalRow, "modulate:a", 1.0, 0.1)
	tween.tween_method(_set_total_text, 0, totalScore, COUNT_TIME)
	tween.tween_callback(_on_total_counted)
	_scoreValue = totalScore


func _set_total_text(value: int) -> void:
	if _totalLabel.text != str(value):
		GlobalAudio.play_sfx("score_tick")
	_totalLabel.text = str(value)


func _on_total_counted() -> void:
	GlobalAudio.play_sfx("pickup_key")
	Fx.flash(_totalLabel, Color(1.8, 1.8, 1.8))
	_nextButton.visible = true
	_nextButton.grab_focus()
	var tween = create_tween()
	_nextButton.scale = Vector2(0.6, 0.6)
	tween.tween_property(_nextButton, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# A key press skips the counting animation
func _unhandled_input(event):
	if _nextButton.visible or !(event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select")):
		return
	for tween in get_tree().get_processed_tweens():
		if tween.is_valid() and tween.is_running():
			tween.custom_step(10.0)
	get_viewport().set_input_as_handled()


func _on_play_button_pressed():
	GlobalTransition.change_scene_to_packed(load(next_scene_path))
