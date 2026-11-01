extends Node2D

## Intro: two T-Rex turn their back, the sheep comes, pulls the chipset out of
## their open computer, swallows it and leaves. The T-Rex, terrified, run after the sheep to get it back.
## Any key, button or click skips to the menu.

@export var target: PackedScene

const FRAME_SIZE := 64

const SHEEP_STOP_X := 160.0
const SHEEP_WALK_SPEED := 90.0
const TREX_RUN_TIME := 1.6
const OUT_X := -120.0

const SHEEP_ANIMATIONS := {
	"walk": ["res://src/Actors/Players/Sheep/sheep-walking.png", 6.0, true],
	"eat": ["res://src/Actors/Players/Sheep/sheep-idle.png", 10.0, true],
	"turn": ["res://src/Actors/Players/Sheep/sheep-turn.png", 8.0, false],
}

const TREX_ANIMATIONS := {
	"idle": ["res://src/Actors/Enemies/TRex/trex-idle.png", 3.0, true],
	"turn": ["res://src/Actors/Enemies/TRex/trex-turn.png", 8.0, false],
	"panic": ["res://src/Actors/Enemies/TRex/trex-attack.png", 14.0, true],
}

@onready var sheep: AnimatedSprite2D = $Sheep
@onready var trex_list: Array[AnimatedSprite2D] = [$TRex1, $TRex2]
@onready var chipset: Sprite2D = $Chipset
@onready var power_light: ColorRect = $Computer/PowerLight
@onready var belly_light: ColorRect = $Sheep/BellyLight

var _is_finished := false


func _ready():
	GlobalAudio.play_music("menu")

	sheep.sprite_frames = _build_frames(SHEEP_ANIMATIONS)
	var trex_frames := _build_frames(TREX_ANIMATIONS)
	for trex in trex_list:
		trex.sprite_frames = trex_frames
		trex.play("idle")
		trex.get_node("Alert").scale = Vector2.ZERO
	belly_light.visible = false
	# Not in sync, they are chatting
	trex_list[1].frame = 2

	_play_intro()


func _unhandled_input(event):
	if event is InputEventKey and event.physical_keycode == KEY_M:
		return
	if event.is_pressed() and !event.is_echo() \
			and (event is InputEventKey or event is InputEventJoypadButton or event is InputEventMouseButton or event is InputEventScreenTouch):
		get_viewport().set_input_as_handled()
		_finish()


func _play_intro() -> void:
	await _wait(0.6)

	# The sheep comes
	sheep.play("walk")
	var tween := create_tween()
	tween.tween_property(sheep, "position:x", SHEEP_STOP_X, (SHEEP_STOP_X - sheep.position.x) / SHEEP_WALK_SPEED)
	await tween.finished

	# ...sniffs the computer, pulls the chipset out of its socket and swallows it whole
	sheep.play("eat")
	await _wait(1.0)
	var mouth := sheep.position + Vector2(28, -24)
	var gulp_tween := create_tween()
	gulp_tween.tween_property(chipset, "position:y", chipset.position.y - 6, 0.15).set_ease(Tween.EASE_OUT)
	gulp_tween.tween_interval(0.15)
	gulp_tween.tween_property(chipset, "position", mouth, 0.15).set_ease(Tween.EASE_IN)
	gulp_tween.parallel().tween_property(chipset, "scale", Vector2.ZERO, 0.15).set_ease(Tween.EASE_IN)
	await gulp_tween.finished
	GlobalAudio.play_sfx("pickup_life", 0.0, -4.0, 0.6)
	_gulp()
	_computer_down()
	await _wait(0.6)

	# ...and leaves
	sheep.play("turn")
	await sheep.animation_finished
	sheep.flip_h = true
	sheep.play("walk")
	tween = create_tween()
	tween.tween_property(sheep, "position:x", OUT_X, (sheep.position.x - OUT_X) / SHEEP_WALK_SPEED)
	await _wait(0.9)

	# The T-Rex turn round: the chipset is gone!
	for trex in trex_list:
		trex.play("turn")
	await trex_list[0].animation_finished
	for trex in trex_list:
		trex.flip_h = true
	await _wait(0.2)

	# Terrified
	GlobalAudio.play_sfx("roar", 0.0, 0.0, 1.5)
	for trex in trex_list:
		trex.play("panic")
		_pop_alert(trex.get_node("Alert"))
		_jump_and_shake(trex, 0.9)
	await _wait(1.0)

	# Run after the sheep
	for i in trex_list.size():
		var trex := trex_list[i]
		var run_tween := create_tween()
		run_tween.tween_interval(i * 0.25)
		run_tween.tween_property(trex, "position:x", OUT_X, TREX_RUN_TIME).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		_hop(trex)
	GlobalAudio.play_sfx("roar", 0.0, -4.0, 1.8)
	await _wait(TREX_RUN_TIME + 0.4)

	_finish()


func _finish() -> void:
	if _is_finished:
		return
	_is_finished = true
	GlobalTransition.change_scene_to_packed(target)


## Waits with a tween bound to this node, so the intro stops when the scene is freed
func _wait(duration: float) -> void:
	var tween := create_tween()
	tween.tween_interval(duration)
	await tween.finished


## The sheep swells as the chipset goes down, then its belly blinks
func _gulp() -> void:
	var base_scale := sheep.scale
	var tween := create_tween()
	tween.tween_property(sheep, "scale", base_scale * Vector2(1.15, 0.85), 0.1)
	tween.tween_property(sheep, "scale", base_scale * Vector2(0.95, 1.1), 0.1)
	tween.tween_property(sheep, "scale", base_scale, 0.1)

	belly_light.visible = true
	var blink_tween := create_tween().set_loops()
	blink_tween.tween_property(belly_light, "modulate:a", 0.2, 0.25)
	blink_tween.tween_property(belly_light, "modulate:a", 1.0, 0.25)


## Without its chipset, the computer goes down
func _computer_down() -> void:
	power_light.color = Color(0.9, 0.2, 0.2)
	var tween := create_tween().set_loops()
	tween.tween_property(power_light, "modulate:a", 0.0, 0.15)
	tween.tween_property(power_light, "modulate:a", 1.0, 0.15)


func _pop_alert(alert: Node2D) -> void:
	var tween := create_tween()
	tween.tween_property(alert, "scale", Vector2(1.4, 1.4), 0.12)
	tween.tween_property(alert, "scale", Vector2.ONE, 0.1)


## Startled jump, then shivers of fear
func _jump_and_shake(sprite: AnimatedSprite2D, duration: float) -> void:
	var base_offset := sprite.offset
	var tween := create_tween()
	tween.tween_property(sprite, "offset:y", base_offset.y - 10, 0.12).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(sprite, "offset:y", base_offset.y, 0.12).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	for i in int(duration / 0.05):
		tween.tween_property(sprite, "offset", base_offset + Vector2(randf_range(-1.5, 1.5), randf_range(-1.0, 0.0)), 0.05)
	tween.tween_property(sprite, "offset", base_offset, 0.05)


## Small panicked hops while running
func _hop(sprite: AnimatedSprite2D) -> void:
	var base_offset := sprite.offset
	var tween := create_tween().set_loops(int(TREX_RUN_TIME / 0.24) + 2)
	tween.tween_property(sprite, "offset:y", base_offset.y - 5, 0.12).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(sprite, "offset:y", base_offset.y, 0.12).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)


## Builds SpriteFrames from horizontal sheets of 64x64 frames
## {name: [texture path, fps, loop]}
func _build_frames(animations: Dictionary) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for anim_name in animations:
		var texture: Texture2D = load(animations[anim_name][0])
		frames.add_animation(anim_name)
		frames.set_animation_speed(anim_name, animations[anim_name][1])
		frames.set_animation_loop(anim_name, animations[anim_name][2])
		for i in texture.get_width() / FRAME_SIZE:
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(i * FRAME_SIZE, 0, FRAME_SIZE, FRAME_SIZE)
			frames.add_frame(anim_name, atlas)
	return frames
