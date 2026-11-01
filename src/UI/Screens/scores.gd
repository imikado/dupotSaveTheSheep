extends Control

# High score table: podium badges for the top 3, the line of the last game
# highlighted, rows sliding in one after the other.

const COLOR_GOLD = Color(1, 0.839216, 0.360784)
const COLOR_SILVER = Color(0.85, 0.87, 0.95)
const COLOR_BRONZE = Color(0.85, 0.55, 0.3)
const COLOR_TEXT = Color(0.92549, 0.937255, 1)
const COLOR_DIM = Color(0.627451, 0.647059, 0.960784)
const COLOR_DARK = Color(0, 0, 0.0588235)
const COLOR_ROW = Color(0.0196078, 0.0392157, 0.172549, 0.6)
const COLOR_ROW_ALT = Color(0.0980392, 0.105882, 0.317647, 0.6)
const COLOR_ROW_LAST = Color(0.360784, 0.380392, 0.835294, 0.55)
const PODIUM_COLORS = [COLOR_GOLD, COLOR_SILVER, COLOR_BRONZE]

const ROW_DELAY = 0.06
const ROW_SLIDE = 24.0

@onready var _menuButton: Button = $menuButton
@onready var _title: Label = $Title
@onready var _table: VBoxContainer = $Panel/Content/ScrollContainer/table
@onready var _scroll: ScrollContainer = $Panel/Content/ScrollContainer

# Line of the game just played, if it made the table
var _lastRow: Control
var _lastRowStyle: StyleBoxFlat


func sort_descending(a, b):
	return a['score'] > b['score']


func _ready() -> void:
	GlobalAudio.play_music("menu")
	$Player.play()
	$Sheep.play()

	var scoreList = GlobalGame.getHighScoreList()
	scoreList.sort_custom(sort_descending)

	$empty.visible = scoreList.is_empty()

	build(scoreList)
	_menuButton.grab_focus()
	_animate()


func build(scoreList):
	var rank = 0
	for scoreLoop in scoreList:
		var isLast = GlobalGame._run_id != "" and scoreLoop.get("run", "") == GlobalGame._run_id
		var row = _create_row(rank, scoreLoop, isLast)
		_table.add_child(row)
		if isLast:
			_lastRow = row
		rank += 1


func _create_row(rank: int, scoreLoop: Dictionary, isLast: bool) -> Control:
	var style = StyleBoxFlat.new()
	style.anti_aliasing = false
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	style.bg_color = COLOR_ROW_ALT if rank % 2 == 1 else COLOR_ROW
	if isLast:
		style.bg_color = COLOR_ROW_LAST
		style.set_border_width_all(1)
		style.border_color = COLOR_GOLD
		_lastRowStyle = style

	var line = PanelContainer.new()
	line.add_theme_stylebox_override("panel", style)
	# Hides the text while it slides in
	line.clip_contents = true

	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	line.add_child(row)

	var textColor = COLOR_TEXT
	if rank < PODIUM_COLORS.size():
		textColor = PODIUM_COLORS[rank]
	elif isLast:
		textColor = COLOR_GOLD

	row.add_child(_create_rank(rank, isLast))

	var dateLabel = Label.new()
	# Seconds are noise in the table
	dateLabel.text = str(scoreLoop.get("date", "")).substr(0, 16)
	dateLabel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dateLabel.add_theme_color_override("font_color", textColor if isLast else COLOR_DIM)
	row.add_child(dateLabel)

	var scoreLabel = Label.new()
	scoreLabel.text = str(int(scoreLoop.score))
	scoreLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	scoreLabel.add_theme_color_override("font_color", textColor)
	row.add_child(scoreLabel)

	return line


# Medal-like badge for the podium, plain number for the others
func _create_rank(rank: int, isLast: bool) -> Control:
	var label = Label.new()
	label.text = str(rank + 1)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(20, 0)

	if rank >= PODIUM_COLORS.size():
		label.add_theme_color_override("font_color", COLOR_GOLD if isLast else COLOR_DIM)
		return label

	var badgeStyle = StyleBoxFlat.new()
	badgeStyle.anti_aliasing = false
	badgeStyle.bg_color = PODIUM_COLORS[rank]
	badgeStyle.set_border_width_all(1)
	badgeStyle.border_color = COLOR_DARK
	badgeStyle.content_margin_top = 1
	badgeStyle.content_margin_bottom = 2
	var badge = PanelContainer.new()
	badge.add_theme_stylebox_override("panel", badgeStyle)
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	label.custom_minimum_size = Vector2(18, 0)
	label.add_theme_color_override("font_color", COLOR_DARK)
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 0)
	badge.add_child(label)
	return badge


func _animate() -> void:
	# Title falls and bounces
	var target_y = _title.position.y
	_title.position.y = target_y - 40
	var tween = create_tween()
	tween.tween_property(_title, "position:y", target_y, 0.5).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

	for line in _table.get_children():
		line.modulate.a = 0.0

	# Containers place the rows during the first frame
	await get_tree().process_frame

	if _lastRow:
		_scroll.ensure_control_visible(_lastRow)

	# Rows slide in from the right, one after the other. The slide moves the
	# row content so the container keeps the layout.
	var delay = 0.15
	for line in _table.get_children():
		var row: Control = line.get_child(0)
		var base_x = row.position.x
		row.position.x = base_x + ROW_SLIDE
		var rowTween = create_tween().set_parallel()
		rowTween.tween_property(line, "modulate:a", 1.0, 0.15).set_delay(delay)
		rowTween.tween_property(row, "position:x", base_x, 0.2).set_delay(delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		delay += ROW_DELAY

	# The line of the last game pulses softly
	if _lastRowStyle:
		var pulse = _lastRow.create_tween().set_loops()
		pulse.tween_property(_lastRowStyle, "border_color", COLOR_GOLD.darkened(0.6), 0.6)
		pulse.tween_property(_lastRowStyle, "border_color", COLOR_GOLD, 0.6)


func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_menu_button_pressed()


func _on_menu_button_pressed() -> void:
	GlobalTransition.change_scene_to_packed(load("res://src/UI/Screens/Menu.tscn"))
