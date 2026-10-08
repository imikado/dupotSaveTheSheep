@tool
class_name PixelBar
extends Control

# Pixel art gauge with a "chip damage" trail:
# on damage the fill drops instantly, the lost part stays visible, blinks,
# then drains, while a floating "-X" shows how much was lost.

const THEME = preload("res://src/UI/Theme.tres")

@export var max_value: float = 100.0:
	set(v):
		max_value = max(v, 1.0)
		queue_redraw()
@export var value: float = 50.0:
	set(v):
		value = v
		_display_value = v
		_ghost_value = v
		queue_redraw()

@export_group("Colors")
@export var fill_color: Color = Color8(51, 194, 71)
@export var low_color: Color = Color8(232, 120, 24)
@export var back_color: Color = Color8(72, 16, 38)
@export var outline_color: Color = Color8(0, 0, 15)
@export var damage_color: Color = Color8(255, 214, 92)
@export var heal_color: Color = Color8(170, 255, 170)
@export var loss_text_color: Color = Color8(255, 70, 70)
@export var gain_text_color: Color = Color8(120, 255, 120)

@export_group("Behaviour")
# Value units between two notches, 0 to disable
@export var segment_size: float = 10.0
# Ratio under which the fill uses low_color, 0 to disable
@export_range(0.0, 1.0) var low_ratio: float = 0.3
@export var show_numbers: bool = true

var _display_value: float = 50.0:
	set(v):
		_display_value = v
		queue_redraw()
var _ghost_value: float = 50.0:
	set(v):
		_ghost_value = v
		queue_redraw()
var _ghost_flash: bool = false:
	set(v):
		_ghost_flash = v
		queue_redraw()

var _initialized: bool = false
var _healing: bool = false
var _tween: Tween
var _popup: Label
var _popup_amount: float = 0.0
var _popup_tween: Tween


# Animated update, first call only initializes the gauge
func set_value_animated(new_value: float) -> void:
	if !_initialized or Engine.is_editor_hint():
		_initialized = true
		value = new_value
		return

	var diff = new_value - value
	if is_zero_approx(diff):
		return
	value_changed(new_value, diff)


func value_changed(new_value: float, diff: float) -> void:
	# keep the trail start if hits are chained
	var ghost_start = max(_ghost_value, _display_value) if diff < 0 else _display_value
	if _tween:
		_tween.kill()
	_ghost_flash = false

	# assigning value resets both internal values, restore the trail
	value = new_value
	_tween = create_tween()

	_healing = diff > 0
	if diff < 0:
		_display_value = new_value
		_ghost_value = ghost_start
		for i in 3:
			_tween.tween_callback(set.bind("_ghost_flash", true))
			_tween.tween_interval(0.07)
			_tween.tween_callback(set.bind("_ghost_flash", false))
			_tween.tween_interval(0.07)
		_tween.tween_interval(0.25)
		_tween.tween_property(self, "_ghost_value", new_value, 0.45) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	else:
		_display_value = ghost_start
		_ghost_value = new_value
		_tween.tween_interval(0.15)
		_tween.tween_property(self, "_display_value", new_value, 0.5) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	if show_numbers:
		_show_popup(diff)


func _show_popup(diff: float) -> void:
	var same_sign = _popup != null and sign(_popup_amount) == sign(diff)
	if !same_sign:
		_clear_popup()
		_popup = Label.new()
		_popup.theme = THEME
		_popup.z_index = 10
		add_child(_popup)
		_popup_amount = 0.0

	_popup_amount += diff
	var amount = int(round(abs(_popup_amount)))
	_popup.text = ("-" if _popup_amount < 0 else "+") + str(amount)
	_popup.add_theme_color_override("font_color", loss_text_color if _popup_amount < 0 else gain_text_color)
	_popup.reset_size()

	# number sits right after the bar, vertically centered
	var base = Vector2(size.x + 3, round((size.y - _popup.size.y) / 2))
	_popup.position = base - Vector2(3, 0)
	_popup.modulate = Color.WHITE

	if _popup_tween:
		_popup_tween.kill()
	_popup_tween = create_tween()
	_popup_tween.tween_property(_popup, "position", base, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_popup_tween.tween_interval(0.6)
	_popup_tween.tween_property(_popup, "position:y", base.y - 4, 0.3)
	_popup_tween.parallel().tween_property(_popup, "modulate:a", 0.0, 0.3)
	_popup_tween.tween_callback(_clear_popup)


func _clear_popup() -> void:
	if _popup != null:
		_popup.queue_free()
		_popup = null
	_popup_amount = 0.0


func _px(v: float, inner_w: float) -> int:
	return int(round(inner_w * clamp(v, 0.0, max_value) / max_value))


func _draw() -> void:
	var w = int(size.x)
	var h = int(size.y)
	if w < 3 or h < 3:
		return
	var inner = Rect2i(1, 1, w - 2, h - 2)

	draw_rect(Rect2i(0, 0, w, h), outline_color)
	draw_rect(inner, back_color)
	# inner shadow on the empty part
	draw_rect(Rect2i(inner.position, Vector2i(inner.size.x, 1)), back_color.darkened(0.4))

	var fill_w = _px(_display_value, inner.size.x)
	var ghost_w = _px(_ghost_value, inner.size.x)

	# trail between fill and ghost
	if ghost_w != fill_w:
		var from = min(fill_w, ghost_w)
		var to = max(fill_w, ghost_w)
		var trail_color = heal_color if _healing else damage_color
		if _ghost_flash:
			trail_color = Color.WHITE
		_draw_shaded(Rect2i(inner.position.x + from, inner.position.y, to - from, inner.size.y), trail_color)

	if fill_w > 0:
		var color = fill_color
		if low_ratio > 0.0 and value <= max_value * low_ratio:
			color = low_color
		_draw_shaded(Rect2i(inner.position, Vector2i(fill_w, inner.size.y)), color)

	# notches every segment_size units
	if segment_size > 0.0:
		var notch_color = outline_color
		notch_color.a = 0.35
		var step = segment_size
		while step < max_value:
			var x = inner.position.x + _px(step, inner.size.x)
			draw_rect(Rect2i(x, inner.end.y - 2, 1, 2), notch_color)
			step += segment_size


# Flat pixel shading: light top line, dark bottom line
func _draw_shaded(rect: Rect2i, color: Color) -> void:
	if rect.size.x <= 0:
		return
	draw_rect(rect, color)
	if rect.size.y >= 3:
		draw_rect(Rect2i(rect.position, Vector2i(rect.size.x, 1)), color.lightened(0.35))
		draw_rect(Rect2i(rect.position.x, rect.end.y - 1, rect.size.x, 1), color.darkened(0.3))
