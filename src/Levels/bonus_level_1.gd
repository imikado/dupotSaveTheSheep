extends Node

@export var _camera: Camera2D
@export var _player: CharacterBody2D
@export var _ground: StaticBody2D

# Speed grows smoothly from start to end of the countdown
const SPEED_START := 170.0
const SPEED_END := 320.0
const BONUS_DURATION := 60.0
const GROUND_WIDTH := 500.0

var currentSpeed := SPEED_START
var _elapsed := 0.0

var screen_size: Vector2i
var camera_start_x = 0

@onready var _endBonusLayer: Control = $Camera2D/BonusControl
@onready var _countDownTimer: Timer = $countDownTimer
@onready var _timeLeftLabel: Label = $Camera2D/Control/timePanel/row/timeLeftLabel
@onready var _timePanel: Control = $Camera2D/Control/timePanel
@onready var _banner: Label = $Camera2D/Control/Label
@onready var _endTitle: Label = $Camera2D/BonusControl/endTitle
@onready var _endScoreLabel: Label = $Camera2D/BonusControl/scorePanel/row/scoreLabel
@onready var _playButton: TextureButton = $Camera2D/BonusControl/PlayButton

# Grabbing a bottle or a burger: slow motion and a close-up window on the bike
const PICKUP_TIME_SCALE := 0.25
# Durations in real seconds (the tween ignores the slow motion)
const INSET_OPEN := 0.15
const INSET_HOLD := 0.55
const INSET_CLOSE := 0.25
const INSET_SIZE := Vector2(176, 100)
const INSET_POSITION := Vector2(152, 30)
const INSET_ZOOM := 2.2
# Middle of the bike drawing, from the body origin
const INSET_FOCUS := Vector2(0, 14)
const INSET_FRAME_COLOR := Color(1, 0.839216, 0.360784)
const INSET_SKY_TOP := Color(0.35, 0.17, 0.38)
const INSET_SKY_BOTTOM := Color(0.98, 0.55, 0.38)
const INSET_TEXT := {"water": "GLUG!", "burger": "YUM!"}
# The road is in the parallax background too: a copy in the world, seen only by the window
const INSET_ONLY_LAYER := 1 << 1
const INSET_ROAD_TEXTURE := preload("res://src/Levels/Shared/bonus_road.png")
const INSET_ROAD_POSITION := Vector2(1, 247)
const INSET_ROAD_LENGTH := 40000

# The grabbed item jumps above the bike then flies to its gauge, which fills on arrival
const PICKUP_ICON_RISE := Vector2(0, -30)
const PICKUP_ICON_SCALE := 2.5
const PICKUP_ICON_POP := 0.15
const PICKUP_ICON_SHOW := 0.3
const PICKUP_ICON_FLY := 0.4
const OUTLINE_MATERIAL := preload("res://src/Shared/outline_pickup.tres")
const BURGER_TEXTURE := preload("res://src/Levels/Shared/burger.png")
const WATER_TEXTURE := preload("res://src/Levels/Shared/water_bottle.png")

var _insetTween: Tween
var _inset: Control
var _insetCamera: Camera2D
var _insetLabel: Label

# Under this many seconds the timer turns red and ticks
const HURRY_TIME = 10
const COLOR_HURRY = Color(1, 0.27451, 0.27451)

@onready var hud = $HUD

@export var Obstacle: PackedScene
@export var WaterBottle: PackedScene
@export var Desserts: PackedScene

@export var nextLevel: PackedScene

@onready var hud_motorbike = $HUD/motorBikeLifes

 
var _countDown = 60

# Items appear just outside the right edge of the screen
const SPAWN_AHEAD := 500.0
# Seconds of riding between two patterns (time based, so it stays fair at high speed)
const GAP_TIME_MIN := 1.1
const GAP_TIME_MAX := 1.9
# Two obstacles in a row: land and jump again right away
const DOUBLE_GAP_TIME := 1.0
const DOUBLE_AFTER := 12.0
# Bottles and burgers lie on the road just before an obstacle: grabbing one means jumping late
const GROUND_ITEM_Y := 30
const ITEM_BEFORE_TIME_MIN := 0.45
const ITEM_BEFORE_TIME_MAX := 0.6
const CLEAR_SCORE := 5
const DESSERTS_EVERY := 8
const BOTTLE_CHANCE := 0.2

var _distance := 0.0
var _nextSpawnAt := 400.0
var _patternCount := 0

var _spawned: Array[Node2D] = []
var _obstacles: Array[Node2D] = []

var _yStart = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	_endBonusLayer.visible = false
	screen_size = get_window().size
	camera_start_x = _camera.position.x
	
	_yStart = _player.position.y
	_createInset()
	_player.connect("picked_up", _on_player_picked_up)
	
	GlobalEvents.player_take_water_bottle.connect(on_player_take_water_bottle)
	
	GlobalEvents.player_gameover.connect(end)

	GlobalEvents.bonus_animation_gameover.connect(on_gameover_animation)

	GlobalEvents.motorbike_hit_obstacle.connect(motorbike_hit_obstacle)
	
	hud.disableProgression()
	
	hud.set_score(GlobalPlayer.get_score())
	hud.set_water(GlobalPlayer.get_water())
	hud.set_player_life(GlobalPlayer.get_life())
	hud.set_sheep_life(GlobalSheep.get_life())
	
	_countDownTimer.start()
	GlobalAudio.play_music("bonus")
	_timeLeftLabel.text = str(_countDown)
	_show_banner()


# "BONUS LEVEL" slides in, blinks, then leaves the screen
func _show_banner():
	var target_x = _banner.position.x
	_banner.position.x = target_x + 480
	var tween = create_tween()
	tween.tween_property(_banner, "position:x", target_x, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for i in 3:
		tween.tween_property(_banner, "modulate:a", 0.3, 0.0).set_delay(0.25)
		tween.tween_property(_banner, "modulate:a", 1.0, 0.0).set_delay(0.25)
	tween.tween_property(_banner, "position:x", target_x - 480, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_callback(_banner.hide)
	
func on_player_take_water_bottle(_water_value):
	_player.take_water(_water_value)
	_add_score(10)


func _add_score(value: int):
	GlobalPlayer.increase_score(value)
	hud.set_score(GlobalPlayer.get_score())
	Fx.popup_text(self, _player.global_position + Vector2(0, -10), "+" + str(value), Fx.COLOR_HEAL)


func on_gameover_animation():
	_stopPickupInset()
	_player.hitedObstacle()


func motorbike_hit_obstacle():
	_stopPickupInset()
	_player.hited()
	hud_motorbike.decrease_life()

func _process(delta):
	_elapsed += delta
	currentSpeed = lerpf(SPEED_START, SPEED_END, clampf(_elapsed / BONUS_DURATION, 0.0, 1.0))

	var step = currentSpeed * delta
	_player.position.x += step
	_camera.position.x += step
	_updateInsetCamera()
	_distance += step

	if _distance >= _nextSpawnAt:
		_spawnPattern()

	_checkClearedObstacles()
	_freeLeftBehind()

	var distance_between_ground = _camera.position.x - camera_start_x - _ground.position.x
	if distance_between_ground >= GROUND_WIDTH:
		_ground.position.x += GROUND_WIDTH


# Picks what comes next; every pattern ends with a free gap to breathe
func _spawnPattern():
	var x = _player.position.x + SPAWN_AHEAD
	var length := 0.0
	_patternCount += 1

	var roll = randf()
	if _patternCount % DESSERTS_EVERY == 0:
		_spawnItemBefore(Desserts, x)
		_spawnObstacle(x)
	elif roll < 0.3 and _elapsed > DOUBLE_AFTER:
		var gap = currentSpeed * DOUBLE_GAP_TIME
		_spawnObstacle(x)
		_spawnObstacle(x + gap)
		length = gap
	else:
		# Now and then a reward for daring to jump at the last moment
		if randf() < BOTTLE_CHANCE:
			_spawnItemBefore(WaterBottle, x)
		_spawnObstacle(x)

	_nextSpawnAt = _distance + length + currentSpeed * randf_range(GAP_TIME_MIN, GAP_TIME_MAX)


func _spawn(scene: PackedScene, x: float, yOffset: float) -> Node2D:
	var item: Node2D = scene.instantiate()
	add_child(item)
	item.position = Vector2(x, _yStart + yOffset)
	_spawned.append(item)
	return item


# On the road before the obstacle at obstacleX; call it before _spawnObstacle so _spawned stays sorted by position
func _spawnItemBefore(scene: PackedScene, obstacleX: float):
	var before = currentSpeed * randf_range(ITEM_BEFORE_TIME_MIN, ITEM_BEFORE_TIME_MAX)
	_spawn(scene, obstacleX - before, GROUND_ITEM_Y)


func _spawnObstacle(x: float):
	_obstacles.append(_spawn(Obstacle, x, 34))


# Obstacles behind the bike without being hit give points
func _checkClearedObstacles():
	_obstacles = _obstacles.filter(func(obstacle): return is_instance_valid(obstacle) and !obstacle.hit)
	while !_obstacles.is_empty() and _obstacles[0].position.x < _player.position.x - 40:
		_obstacles.pop_front()
		_add_score(CLEAR_SCORE)


func _freeLeftBehind():
	var limit = _camera.position.x - 300
	_spawned = _spawned.filter(is_instance_valid)
	while !_spawned.is_empty() and _spawned[0].position.x < limit:
		_spawned.pop_front().queue_free()


func _on_play_button_pressed():
	GlobalTransition.change_scene_to_packed(nextLevel)


func _on_player_picked_up(item: String):
	if item == "water":
		_flyToHud(_waterIcon(), $HUD/Water/icon, func(): hud.set_water(GlobalPlayer.get_water()))
	else:
		# The burger heals both: one for Max, one for the sheep
		_flyToHud(BURGER_TEXTURE, $HUD/Player/icon, func(): hud.set_player_life(GlobalPlayer.get_life()))
		_flyToHud(BURGER_TEXTURE, $HUD/Sheep/icon, func(): hud.set_sheep_life(GlobalSheep.get_life()), PICKUP_ICON_FLY * 0.25)
	_showPickupInset(item)


func _waterIcon() -> Texture2D:
	var icon := AtlasTexture.new()
	icon.atlas = WATER_TEXTURE
	icon.region = Rect2(0, 0, 16, 16)
	return icon


# Real time tween: it stays readable during the slow motion
func _flyToHud(texture: Texture2D, target: Control, onArrival: Callable, delay := 0.0):
	var icon := Sprite2D.new()
	icon.texture = texture
	icon.material = OUTLINE_MATERIAL
	icon.scale = Vector2.ZERO
	hud.add_child(icon)
	var start = _player.get_global_transform_with_canvas().origin + Vector2(0, -10)
	icon.position = start
	var end = target.global_position + target.size / 2

	var tween = icon.create_tween().set_ignore_time_scale(true)
	tween.tween_property(icon, "scale", Vector2.ONE * PICKUP_ICON_SCALE, PICKUP_ICON_POP).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(icon, "position", start + PICKUP_ICON_RISE, PICKUP_ICON_POP).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(icon, "rotation", 0.2, PICKUP_ICON_SHOW / 2).set_trans(Tween.TRANS_SINE)
	tween.tween_property(icon, "rotation", 0.0, PICKUP_ICON_SHOW / 2).set_trans(Tween.TRANS_SINE)
	tween.tween_interval(delay)
	tween.tween_property(icon, "position", end, PICKUP_ICON_FLY).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(icon, "scale", Vector2.ONE, PICKUP_ICON_FLY).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(onArrival)
	tween.tween_callback(icon.queue_free)


# Comic style window, drawn by a second view of the same world, zoomed on the bike
func _createInset():
	_inset = Control.new()
	_inset.position = INSET_POSITION
	_inset.size = INSET_SIZE
	_inset.pivot_offset = INSET_SIZE / 2
	_inset.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_inset.visible = false

	# The parallax sky is not part of the world: paint one behind it
	var gradient := Gradient.new()
	gradient.set_color(0, INSET_SKY_TOP)
	gradient.set_color(1, INSET_SKY_BOTTOM)
	var skyTexture := GradientTexture2D.new()
	skyTexture.gradient = gradient
	skyTexture.fill_from = Vector2(0, 0)
	skyTexture.fill_to = Vector2(0, 1)
	var sky := TextureRect.new()
	sky.texture = skyTexture
	sky.size = INSET_SIZE
	_inset.add_child(sky)

	var road := Sprite2D.new()
	road.texture = INSET_ROAD_TEXTURE
	road.centered = false
	road.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	road.region_enabled = true
	road.region_rect = Rect2(0, 0, INSET_ROAD_LENGTH, INSET_ROAD_TEXTURE.get_height())
	road.position = INSET_ROAD_POSITION
	road.visibility_layer = INSET_ONLY_LAYER
	road.z_index = -1
	add_child(road)
	get_viewport().canvas_cull_mask &= ~INSET_ONLY_LAYER

	var container := SubViewportContainer.new()
	container.stretch = true
	container.size = INSET_SIZE
	_inset.add_child(container)
	var view := SubViewport.new()
	view.world_2d = get_viewport().world_2d
	view.transparent_bg = true
	view.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	container.add_child(view)
	_insetCamera = Camera2D.new()
	_insetCamera.zoom = Vector2(INSET_ZOOM, INSET_ZOOM)
	view.add_child(_insetCamera)

	var frameStyle := StyleBoxFlat.new()
	frameStyle.draw_center = false
	frameStyle.set_border_width_all(2)
	frameStyle.border_color = INSET_FRAME_COLOR
	frameStyle.shadow_color = Color.BLACK
	frameStyle.shadow_size = 2
	var frame := Panel.new()
	frame.add_theme_stylebox_override("panel", frameStyle)
	frame.size = INSET_SIZE
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_inset.add_child(frame)

	_insetLabel = Label.new()
	_insetLabel.add_theme_font_override("font", Fx.FONT)
	_insetLabel.add_theme_font_size_override("font_size", 8)
	_insetLabel.add_theme_color_override("font_color", INSET_FRAME_COLOR)
	_insetLabel.add_theme_color_override("font_outline_color", Color.BLACK)
	_insetLabel.add_theme_constant_override("outline_size", 3)
	_insetLabel.position = Vector2(6, 2)
	_inset.add_child(_insetLabel)

	hud.add_child(_inset)
	# Under the pause screen
	hud.move_child(_inset, 0)


func _updateInsetCamera():
	if _inset.visible:
		_insetCamera.global_position = _player.global_position + INSET_FOCUS


func _showPickupInset(item: String):
	if _insetTween:
		_insetTween.kill()
	Engine.time_scale = PICKUP_TIME_SCALE
	_insetLabel.text = INSET_TEXT[item]
	_inset.visible = true
	_updateInsetCamera()
	_insetTween = create_tween().set_ignore_time_scale(true)
	_insetTween.tween_property(_inset, "scale", Vector2.ONE, INSET_OPEN).from(Vector2(0.2, 0.2)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_insetTween.tween_interval(INSET_HOLD)
	_insetTween.tween_property(_inset, "scale", Vector2(0.2, 0.2), INSET_CLOSE).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	_insetTween.parallel().tween_property(Engine, "time_scale", 1.0, INSET_CLOSE).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_insetTween.tween_callback(_inset.hide)


# A crash or the end of the bonus must not stay slowed down
func _stopPickupInset():
	if _insetTween:
		_insetTween.kill()
		_insetTween = null
	Engine.time_scale = 1.0
	_inset.hide()


func _exit_tree():
	Engine.time_scale = 1.0


func end():
	if _endBonusLayer.visible:
		return
	_stopPickupInset()
	_countDownTimer.stop()
	set_process(false)
	_endTitle.text = "TIME UP!" if _countDown <= 0 else "CRASH!"
	_endScoreLabel.text = str(GlobalPlayer.get_score())
	_endBonusLayer.visible = true
	_banner.hide()
	GlobalAudio.play_jingle("level_complete" if _countDown <= 0 else "game_over")

	var target_y = _endTitle.position.y
	_endTitle.position.y = target_y - 50
	var tween = create_tween()
	tween.tween_property(_endTitle, "position:y", target_y, 0.6).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_playButton.grab_focus)


func _on_count_down_timer_timeout():
	_countDown -= 1
	_timeLeftLabel.text = str(_countDown)
	if _countDown <= 0:
		end()
		return

	if _countDown <= HURRY_TIME:
		GlobalAudio.play_sfx("tick")
		_timeLeftLabel.add_theme_color_override("font_color", COLOR_HURRY)
		var tween = create_tween()
		_timePanel.pivot_offset = _timePanel.size / 2
		_timePanel.scale = Vector2(1.2, 1.2)
		tween.tween_property(_timePanel, "scale", Vector2.ONE, 0.2)
