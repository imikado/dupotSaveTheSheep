extends CharacterBody2D
class_name Player


const SPEED = 100.0
const JUMP_VELOCITY = -150.0

const AREA='PlayerArea'

const SHOOT_WATER_VALUE=1

var pending_water=0
var pending_life=0

var carry_sheep=false

var direction

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

signal action_finished

@onready var _state_machine:PlayerStateMachine = $StateMachine
@onready var _sprite:Sprite2D = $Sprite2D

@onready var _raycast:RayCast2D=$RayCast2D

@export var _sheep:Sheep 

@export var muzzleMarker2d:Marker2D

@onready var Bullet = load("res://src/Actors/Players/Bullet.tscn")


func _physics_process(delta):
	
	if get_current_state().has_gravity:
		update_gravity(delta)
	
	if get_current_state().can_move:
		update_move(delta)
	else:
		update_min_move(delta)
	
	if get_current_state().can_jump:
		update_jump(delta)
	
	if get_current_state().can_takeOutGun:
		update_takeoutgun(delta)
	
	if get_current_state().can_shoot:
		update_gunshoot(delta)

	if _sprite.flip_h:
		muzzleMarker2d.position.x=-25
	else:
		muzzleMarker2d.position.x=25	
	
	
		
	get_current_state().state_physics_process(delta)


	process_move()
	
func process_jump(_delta):
	velocity.y = JUMP_VELOCITY

#func _physics_process(delta):
func update_gravity(delta):
	# Add the gravity.
	if not is_on_floor():
		set_new_state(PlayerStateMachine.STATE_FALL)
		velocity.y += gravity * delta

func update_jump(_delta):
	if GlobalInput.is_press_jump_button() and is_on_floor():
		set_new_state(PlayerStateMachine.STATE_JUMP)

func update_takeoutgun(_delta):
	if GlobalInput.is_press_attack_button():
		set_new_state(PlayerStateMachine.STATE_TAKEOUTGUN)

func update_gunshoot(_delta):
	if GlobalInput.is_press_attack_button():
		set_new_state(PlayerStateMachine.STATE_GUNSHOOT)

func shoot():

	if !GlobalPlayer.can_use_amount_water(SHOOT_WATER_VALUE):
		print('cannot user water '+str(SHOOT_WATER_VALUE))
		return

	var bullet=Bullet.instantiate()
	get_parent().add_child(bullet)
	
	bullet.global_position=muzzleMarker2d.global_position
	if _sprite.flip_h:
		bullet.run(-1)
	else:
		bullet.run(1)

	GlobalPlayer.use_amount_water(SHOOT_WATER_VALUE)

	GlobalEvents.emit_signal("player_water_changed",GlobalPlayer.get_water())


func update_carry_sheep():
	if !carry_sheep and GlobalInput.is_press_carry_button() and is_on_floor():
		if abs(_sheep.position.x - position.x) <30:
			print('carry sheep')
			
			_sheep.be_carried()
			_sheep.position.x=position.x+2
			_sheep.position.y-=35
			_sheep.reparent(self)
			
			add_child(_sheep)
			
			carry_sheep=true
	elif carry_sheep and GlobalInput.is_press_carry_button() and is_on_floor():
		_sheep.reparent(get_parent())
		_sheep.position.x+=10*direction
		_sheep.position.y+=28
		_sheep.bring_back()
		
		carry_sheep=false



func update_move(_delta):
	var currentSpeed= get_current_speed()
	
	direction = GlobalInput.get_direction()
	if direction:
		set_new_state(PlayerStateMachine.STATE_WALKING)
		velocity.x = direction * currentSpeed
		
		_sprite.flip_h=(direction==-1)
		
	else:
		if !_raycast.is_colliding():
			set_new_state(PlayerStateMachine.STATE_EDGE)
			velocity.x = move_toward(velocity.x, 0, currentSpeed)

		else:
			if get_current_state().can_idle:
				set_new_state(PlayerStateMachine.STATE_IDLE)
			velocity.x = move_toward(velocity.x, 0, currentSpeed)

func update_min_move(_delta):
	if velocity.x!=0:
		return

	if  [PlayerStateMachine.STATE_TAKINGWATER,PlayerStateMachine.STATE_ACTION,PlayerStateMachine.STATE_TAKINGBURGER].has(get_current_state().name):
		return
		
	var currentSpeed= get_current_speed()/2
	
	direction = GlobalInput.get_direction()
	if direction:
		velocity.x = direction *currentSpeed
		
		_sprite.flip_h=(direction==-1)


func process_move():
	move_and_slide()
	
func set_new_state(new_state):
	_state_machine.set_state(new_state)

func get_current_state()->State:
	return _state_machine.current_state
	
func get_current_speed():
	return SPEED


func hit_damage(damage):
	set_new_state(PlayerStateMachine.STATE_DAMAGED)
	var tween := create_tween()
	tween.tween_property(self,"modulate",Color.RED,0.3)
	tween.tween_property(self,"modulate",Color.WHITE,0.2)
	tween.tween_property(self,"modulate",Color.RED,0.3)
	tween.tween_property(self,"modulate",Color.WHITE,0.2)
	
	GlobalEvents.player_take_damage.emit(damage)

	
func take_water(water_value):
	direction=0
	velocity.x=0
	#velocity.y=0
	pending_water=water_value
	set_new_state(PlayerStateMachine.STATE_TAKINGWATER)

func commit_water():
	GlobalEvents.emit_signal("player_water_changed",pending_water)
	pending_water=0

func action():
	direction=0
	velocity.x=0
	set_new_state(PlayerStateMachine.STATE_ACTION)

	await action_finished


func commit_action():
	action_finished.emit()

func take_burger(value):
	direction=0
	velocity.x=0
	#velocity.y=0
	pending_life=value
	set_new_state(PlayerStateMachine.STATE_TAKINGBURGER)

func commit_increase_life():
	GlobalEvents.player_increase_life.emit(pending_life)
	pending_life=0
