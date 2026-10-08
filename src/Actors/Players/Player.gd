extends CharacterBody2D
class_name Player


const SPEED = 100.0
const JUMP_VELOCITY = -300.0
const BOUNCE_VELOCITY = -180.0
const AIR_ACCELERATION = 600.0
const FALL_GRAVITY_MULTIPLIER = 1.6
const MAX_FALL_SPEED = 400.0
const COYOTE_TIME = 0.1
const JUMP_BUFFER_TIME = 0.12
const SPRITE_Y = -32.0

const AREA = 'PlayerArea'

const SHOOT_WATER_VALUE = 1
const DAMAGE_INVULNERABILITY_TIME = 1.0
const DAMAGE_KNOCKBACK = 160.0
const DAMAGE_UPWARD_BOUNCE = -90.0

var _pending_water = 0
var _pending_life = 0
var _pending_action = null
var _pending_vehicle = null

var _direction
var _damage_invulnerability_timer := 0.0

var _coyote_timer := 0.0
var _jump_buffer_timer := 0.0
var _was_on_floor := true

# Rising gravity: gives the same jump height (~72px) as before with a real arc.
var _gravity = JUMP_VELOCITY * JUMP_VELOCITY / (2.0 * 72.0)

signal action_finished

@onready var _state_machine: PlayerStateMachine = $StateMachine
@onready var _sprite: Sprite2D = $Sprite2D

@onready var _raycast: RayCast2D = $RayCast2D


@export var _muzzleMarker2d: Marker2D

@onready var Bullet = load("res://src/Actors/Players/Bullet.tscn")

var _hasKey:bool= false

func _physics_process(delta):

	if _damage_invulnerability_timer > 0.0:
		_damage_invulnerability_timer = max(_damage_invulnerability_timer - delta, 0.0)
		if _damage_invulnerability_timer > 0.0:
			modulate = Color.WHITE if int(_damage_invulnerability_timer * 20.0) % 2 == 0 else Color(1.4, 0.7, 0.7)
		else:
			modulate = Color.WHITE

	if _pending_vehicle != null:
		queue_free()
		_pending_vehicle.player_go_from_left()
		return
	
	if get_current_state().has_gravity:
		update_gravity(delta)
	
	if is_in_air_state():
		update_air_move(delta)
	elif get_current_state().can_move:
		update_move(delta)
	else:
		update_min_move(delta)
	
	update_jump(delta)
	
	if get_current_state().can_takeOutGun:
		update_takeoutgun(delta)
	
	if get_current_state().can_shoot:
		update_gunshoot(delta)

	if _sprite.flip_h:
		_muzzleMarker2d.position.x = -25
	else:
		_muzzleMarker2d.position.x = 25
	
	
	process_move()
	update_landing()

func get_key():
	_hasKey=true

func has_key():
	return _hasKey

# Bounce (on the sheep or an enemy head)
func process_jump(_delta):
	velocity.y = BOUNCE_VELOCITY
	stretch()

func start_jump():
	velocity.y = JUMP_VELOCITY
	_coyote_timer = 0
	_jump_buffer_timer = 0
	Fx.dust(get_parent(), global_position)
	stretch()

func is_in_air_state() -> bool:
	return [PlayerStateMachine.STATE_JUMP, PlayerStateMachine.STATE_FALL].has(get_current_state().name)

func update_gravity(delta):
	if is_on_floor():
		return
	if !is_in_air_state():
		set_new_state(PlayerStateMachine.STATE_FALL)
	# Fall faster than rising: snappier, less floaty jumps
	var gravity = _gravity
	if velocity.y > 0:
		gravity *= FALL_GRAVITY_MULTIPLIER
	velocity.y = min(velocity.y + gravity * delta, MAX_FALL_SPEED)

func update_jump(delta):
	# Coyote time: still allowed to jump shortly after walking off a ledge
	if is_on_floor():
		_coyote_timer = COYOTE_TIME
	else:
		_coyote_timer = max(_coyote_timer - delta, 0.0)

	# Jump buffer: a press just before landing is not lost
	_jump_buffer_timer = max(_jump_buffer_timer - delta, 0.0)
	if GlobalInput.is_press_jump_button():
		_jump_buffer_timer = JUMP_BUFFER_TIME

	var state = get_current_state()
	var can_jump_now = state.can_jump or state.name == PlayerStateMachine.STATE_FALL
	if _jump_buffer_timer > 0 and _coyote_timer > 0 and can_jump_now and velocity.y >= 0:
		set_new_state(PlayerStateMachine.STATE_JUMP)

func update_landing():
	var on_floor = is_on_floor()
	if on_floor and !_was_on_floor:
		Fx.dust(get_parent(), global_position)
		squash()
	_was_on_floor = on_floor

func update_air_move(delta):
	_direction = GlobalInput.get_direction()
	velocity.x = move_toward(velocity.x, _direction * SPEED, AIR_ACCELERATION * delta)
	if _direction:
		_sprite.flip_h = (_direction < 0)

func squash():
	_tween_sprite_scale(Vector2(1.25, 0.8))

func stretch():
	_tween_sprite_scale(Vector2(0.85, 1.15))

func _tween_sprite_scale(target_scale: Vector2):
	var tween = create_tween()
	tween.tween_method(_set_sprite_scale, target_scale, Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# Scale from the feet so the sprite stays on the ground
func _set_sprite_scale(new_scale: Vector2):
	_sprite.scale = new_scale
	_sprite.position.y = SPRITE_Y * new_scale.y

func update_takeoutgun(_delta):
	if GlobalInput.is_press_attack_button():
		# Plant the feet: drawing the gun fires right away
		velocity.x = 0
		set_new_state(PlayerStateMachine.STATE_TAKEOUTGUN)

func update_gunshoot(_delta):
	if GlobalInput.is_press_attack_button():
		velocity.x = 0
		set_new_state(PlayerStateMachine.STATE_GUNSHOOT)

func shoot():

	if !GlobalPlayer.can_use_amount_water(SHOOT_WATER_VALUE):
		GlobalEvents.player_out_of_water.emit()
		return

	var bullet = Bullet.instantiate()
	get_parent().add_child(bullet)
	
	bullet.global_position = _muzzleMarker2d.global_position
	if _sprite.flip_h:
		bullet.run(-1)
	else:
		bullet.run(1)

	GlobalPlayer.use_amount_water(SHOOT_WATER_VALUE)

	GlobalEvents.emit_signal("player_water_changed", GlobalPlayer.get_water())


func update_move(_delta):

	if _pending_action != null and GlobalInput.is_press_action_button():
		action()

	var currentSpeed = get_current_speed()
	
	_direction = GlobalInput.get_direction()
	if _direction:
		set_new_state(PlayerStateMachine.STATE_WALKING)
		velocity.x = _direction * currentSpeed
		
		_sprite.flip_h = (_direction == -1)
		
	else:
		if !_raycast.is_colliding():
			set_new_state(PlayerStateMachine.STATE_EDGE)
			velocity.x = move_toward(velocity.x, 0, currentSpeed)

		else:
			if get_current_state().can_idle:
				set_new_state(PlayerStateMachine.STATE_IDLE)
			velocity.x = move_toward(velocity.x, 0, currentSpeed)

func update_min_move(_delta):
	if velocity.x != 0:
		return

	if [PlayerStateMachine.STATE_TAKINGWATER, PlayerStateMachine.STATE_ACTION, PlayerStateMachine.STATE_TAKINGBURGER, PlayerStateMachine.STATE_TAKEOUTGUN, PlayerStateMachine.STATE_GUNSHOOT].has(get_current_state().name):
		return
		
	var currentSpeed = 0
	
	if get_current_state().name == PlayerStateMachine.STATE_JUMP:
		currentSpeed = get_current_speed()
	else:
		currentSpeed = get_current_speed() / 2

	_direction = GlobalInput.get_direction()
	if _direction:
		velocity.x = _direction * currentSpeed
		
		_sprite.flip_h = (_direction == -1)


func process_move():
	move_and_slide()
	
func set_new_state(new_state):
	_state_machine.set_state(new_state)

func get_current_state() -> State:
	return _state_machine.current_state
	
func get_current_speed():
	return SPEED


func hit_damage(damage):
	if _damage_invulnerability_timer > 0.0:
		return

	_damage_invulnerability_timer = DAMAGE_INVULNERABILITY_TIME
	set_new_state(PlayerStateMachine.STATE_DAMAGED)
	var knockback_direction := 1.0
	if _direction != 0:
		knockback_direction = -_direction
	elif _sprite.flip_h:
		knockback_direction = 1.0
	else:
		knockback_direction = -1.0
	velocity.x = knockback_direction * DAMAGE_KNOCKBACK
	velocity.y = min(velocity.y, DAMAGE_UPWARD_BOUNCE)
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.RED, 0.1)
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)
	Fx.shake(self, 4.0, 0.3)
	
	GlobalEvents.player_take_damage.emit(damage)

	
func take_water(water_value):
	_direction = 0
	velocity.x = 0
	#velocity.y=0
	_pending_water = water_value
	set_new_state(PlayerStateMachine.STATE_TAKINGWATER)

func commit_water():
	GlobalEvents.emit_signal("player_water_changed", _pending_water)
	_pending_water = 0

func action():
	_direction = 0
	velocity.x = 0
	set_new_state(PlayerStateMachine.STATE_ACTION)

func commit_action():
	_pending_action.action()

func take_burger(value):
	_direction = 0
	velocity.x = 0
	#velocity.y=0
	_pending_life = value
	set_new_state(PlayerStateMachine.STATE_TAKINGBURGER)

func commit_increase_life():
	GlobalEvents.player_increase_life.emit(_pending_life)
	_pending_life = 0

func set_pending_action(pending_action):
	_pending_action = pending_action

func reset_pending_action():
	_pending_action = null


func set_pending_vehicle(pending_vehicle):
	_pending_vehicle = pending_vehicle

func reset_pending_vehicle():
	_pending_vehicle = null
