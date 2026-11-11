extends CharacterBody2D
class_name PlayerOnMotorBike

# Always a full jump: the obstacles and the high items are spaced for it
const JUMP_VELOCITY = -300.0
const RISE_GRAVITY_SCALE = 0.8
# Falls a bit faster than it rises: less floaty, keeps enough air time at top speed
const FALL_GRAVITY_SCALE = 1.0
# A press slightly before landing still jumps
const JUMP_BUFFER = 0.15
# A press slightly after leaving the ground still jumps
const COYOTE_TIME = 0.08

# Nose up when taking off, back to flat while falling
const TAKE_OFF_ANGLE = -0.45
const TILT_SPEED = 12.0
const SQUASH_LAND = Vector2(1.2, 0.8)
const STRETCH_JUMP = Vector2(0.85, 1.15)
const SQUASH_PICKUP = Vector2(1.15, 0.9)
const PICKUP_FLASH = Color(1.8, 1.8, 1.8)
# Last frame of TakeWater/TakeDesserts: the item is in hand. The frames before
# bend down to the road, so they are skipped in the air
const PICKUP_IN_HAND_TIME = 0.18

const INVINCIBLE_TIME = 1.2

# Two players mode: player 2 rides his own motorbike, without the sheep, with
# his own sprites (tools/generate_player2.py)
const SOLO_TEXTURES = {
	"res://src/Actors/Vehicles/motobike-riding.png": preload("res://src/Actors/Vehicles/motobike-riding-player2.png"),
	"res://src/Actors/Vehicles/motobike-take-water.png": preload("res://src/Actors/Vehicles/motobike-take-water-player2.png"),
	"res://src/Actors/Vehicles/motobike-take-desserts.png": preload("res://src/Actors/Vehicles/motobike-take-desserts-player2.png"),
}

var player_index := 1
var has_sheep := true

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# A bottle ("water") or a burger ("burger") has been grabbed: the level highlights it
signal picked_up(item: String)

@onready var animationPlayer := $AnimationPlayer
@onready var _sprite: Sprite2D = $motorbike

enum STATE {RIDING, TAKE_WATER, OBSTACLE, TAKE_DESSERTS, HITED}

var _state = STATE.RIDING
var _animationList = {
	STATE.RIDING: 'riding',
	STATE.TAKE_WATER: 'TakeWater',
	STATE.OBSTACLE: 'obstacle',
	STATE.TAKE_DESSERTS: 'TakeDesserts',
	STATE.HITED: 'hited'
}

var _jumpBuffer := 0.0
var _coyote := 0.0
var _wasOnFloor := true
var _invincible := 0.0
var _squashTween: Tween

func _ready():
	ride()

func getAnimation(stateToCheck) -> String:
	return _animationList[stateToCheck]

func is_crashed() -> bool:
	return isState(STATE.OBSTACLE)

func is_invincible() -> bool:
	return _invincible > 0.0 or is_crashed()

func hitedObstacle():
	GlobalAudio.play_sfx("bike_crash", 0.0, 0.0, 0.7)
	_sprite.rotation = 0.0
	_sprite.scale = Vector2.ONE
	setState(STATE.OBSTACLE)

func ride():
	setState(STATE.RIDING)

# Player 2 without the sheep on his motorbike: rides alone
func setup_solo(index: int):
	player_index = index
	has_sheep = false
	var library: AnimationLibrary = animationPlayer.get_animation_library("").duplicate(true)
	for animationName in library.get_animation_list():
		var animation := library.get_animation(animationName)
		for track in animation.get_track_count():
			if animation.track_get_path(track) != NodePath("motorbike:texture"):
				continue
			for key in animation.track_get_key_count(track):
				var texture = animation.track_get_key_value(track, key)
				if texture is Texture2D and SOLO_TEXTURES.has(texture.resource_path):
					animation.track_set_key_value(track, key, SOLO_TEXTURES[texture.resource_path])
	animationPlayer.remove_animation_library("")
	animationPlayer.add_animation_library("", library)
	if SOLO_TEXTURES.has(_sprite.texture.resource_path):
		_sprite.texture = SOLO_TEXTURES[_sprite.texture.resource_path]
	setState(_state)

func take_desserts(_life):
	GlobalPlayer.increase_life(10, player_index)
	if has_sheep:
		GlobalSheep.increase_life(10)
	GlobalEvents.player_health_changed.emit(GlobalPlayer.get_life())
	GlobalEvents.sheep_health_changed.emit(GlobalSheep.get_life())
	_playPickup(STATE.TAKE_DESSERTS)
	picked_up.emit("burger")

func hited():
	GlobalAudio.play_sfx("bike_crash", 0.05)
	_invincible = INVINCIBLE_TIME
	Fx.smoke(get_parent(), global_position + Vector2(10, 10))
	Fx.shake(self, 4.0, 0.3)
	setState(STATE.HITED)

func take_water(_water_value):
	_playPickup(STATE.TAKE_WATER)
	picked_up.emit("water")

# A pickup must not cut the hit animation (it shows the invincibility)
func _playPickup(newState):
	if isState(STATE.RIDING) or isState(STATE.TAKE_WATER) or isState(STATE.TAKE_DESSERTS):
		animationPlayer.stop()
		setState(newState)
		if !is_on_floor():
			_skipToItemInHand()
	Fx.flash(_sprite, PICKUP_FLASH)
	_squash(SQUASH_PICKUP)

# The item lies just before an obstacle: the jump often starts while grabbing it
func _skipToItemInHand():
	if (isState(STATE.TAKE_WATER) or isState(STATE.TAKE_DESSERTS)) and animationPlayer.current_animation_position < PICKUP_IN_HAND_TIME:
		animationPlayer.seek(PICKUP_IN_HAND_TIME, true)

func isState(stateToCheck) -> bool:
	return _state == stateToCheck

func setState(newState):
	_state = newState
	animationPlayer.play(_animationList[newState])

func _squash(amount: Vector2):
	if _squashTween:
		_squashTween.kill()
	_sprite.scale = amount
	_squashTween = create_tween()
	_squashTween.tween_property(_sprite, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _jump():
	velocity.y = JUMP_VELOCITY
	_jumpBuffer = 0.0
	_coyote = 0.0
	_skipToItemInHand()
	GlobalAudio.play_sfx("jump", 0.05, 0.0, 0.85)
	Fx.dust(get_parent(), global_position + Vector2(-20, 36))
	_squash(STRETCH_JUMP)

func _land():
	GlobalAudio.play_sfx("land", 0.1, -6.0)
	Fx.dust(get_parent(), global_position + Vector2(0, 36))
	_squash(SQUASH_LAND)

func _physics_process(delta):
	if is_crashed():
		return

	_invincible = maxf(_invincible - delta, 0.0)

	var onFloor := is_on_floor()

	if onFloor:
		_coyote = COYOTE_TIME
	else:
		_coyote = maxf(_coyote - delta, 0.0)
		var gravityScale = RISE_GRAVITY_SCALE if velocity.y < 0 else FALL_GRAVITY_SCALE
		velocity.y += gravity * delta * gravityScale

	if GlobalInput.is_press_jump_button(player_index):
		_jumpBuffer = JUMP_BUFFER
	else:
		_jumpBuffer = maxf(_jumpBuffer - delta, 0.0)

	if _jumpBuffer > 0.0 and _coyote > 0.0:
		_jump()

	move_and_slide()

	onFloor = is_on_floor()
	if onFloor and !_wasOnFloor:
		_land()
	_wasOnFloor = onFloor

	_updateTilt(delta, onFloor)

func _updateTilt(delta: float, onFloor: bool):
	var targetAngle := 0.0
	if !onFloor:
		var fallRatio := inverse_lerp(JUMP_VELOCITY, 0.0, velocity.y)
		targetAngle = lerpf(TAKE_OFF_ANGLE, 0.0, clampf(fallRatio, 0.0, 1.0))
	_sprite.rotation = lerp_angle(_sprite.rotation, targetAngle, 1.0 - exp(-TILT_SPEED * delta))

	# Blinks while invincible after a hit
	_sprite.visible = _invincible <= 0.0 or int(_invincible * 15.0) % 2 == 0

func _on_animation_player_animation_finished(anim_name):
	if anim_name == getAnimation(STATE.OBSTACLE):
		GlobalEvents.player_gameover.emit()
	elif anim_name != getAnimation(STATE.RIDING):
		ride()
