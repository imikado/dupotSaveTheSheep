extends Node2D
class_name CoopAction

## Two players mode: a gate, a handle or an elevator only moves once both
## players did the action on it. The first one waits (prompt above his head)
## while he stays on it, for WAIT_TIME at most.

const NODE_NAME := "CoopAction"
const WAIT_TIME := 6.0
const COLOR_DONE := Color(0.5, 1.0, 0.5)
const HEAD_OFFSET := Vector2(0, -74)

var _target: Node
var _done: Array[int] = []
var _label: Label
var _time := 0.0


static func request(target: Node, player: Player) -> void:
	if !is_instance_valid(target):
		return
	if !GlobalGame.is_two_players() or GlobalPlayer.get_actors().size() < 2:
		target.action()
		return
	_find(target, true)._add(player)


static func cancel(target: Node, player: Player) -> void:
	if !is_instance_valid(target):
		return
	var coop := _find(target, false)
	if coop != null:
		coop._remove(player)


static func _find(target: Node, create: bool) -> CoopAction:
	var coop := target.get_node_or_null(NODE_NAME) as CoopAction
	if coop == null and create:
		coop = CoopAction.new()
		coop.name = NODE_NAME
		coop._target = target
		target.add_child(coop)
	return coop


func _ready() -> void:
	top_level = true
	z_index = 30
	z_as_relative = false
	_label = Label.new()
	_label.add_theme_font_override("font", Fx.FONT)
	_label.add_theme_font_size_override("font_size", 8)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 3)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.size = Vector2(120, 14)
	_label.position = Vector2(-60, -7)
	add_child(_label)
	var tween := create_tween().set_loops()
	tween.tween_property(_label, "modulate:a", 0.35, 0.3)
	tween.tween_property(_label, "modulate:a", 1.0, 0.3)


func _process(delta: float) -> void:
	_time += delta
	if _time >= WAIT_TIME:
		queue_free()


func _add(player: Player) -> void:
	_time = 0.0
	if not player.player_index in _done:
		_done.append(player.player_index)
	if _done.size() >= GlobalPlayer.get_actors().size():
		Fx.popup_text(_target, player.global_position + HEAD_OFFSET, "GO!", COLOR_DONE)
		_target.action()
		queue_free()
		return
	GlobalAudio.play_sfx("tick")
	global_position = player.global_position + HEAD_OFFSET
	var waited := 2 if player.player_index == 1 else 1
	_label.text = "P%d: ACTION! (%d/2)" % [waited, _done.size()]
	# Color of the player who is waited for
	_label.add_theme_color_override("font_color", Player.COOP_COLORS[waited])


func _remove(player: Player) -> void:
	_done.erase(player.player_index)
	if _done.is_empty():
		queue_free()
