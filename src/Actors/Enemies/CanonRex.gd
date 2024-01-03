extends Enemy
class_name CanonRex

@onready var _animationPlayer=$AnimationPlayer
@onready var _sprite=$Sprite2D

@onready var _state_machine:CanonRexStateMachine = $StateMachine

@export var FireBall:PackedScene

@onready var spawnFireBall:Marker2D=$Marker2D
@onready var shootTimer:Timer=$Timer


const INPULSE_LEFT=-25
const INPULSE_RIGHT=70

var life =10

var current_state_name=""
var moveVector=Vector2(INPULSE_LEFT,0)



func die():
	set_new_state(CanonRexStateMachine.STATE_DIE)
		
func finish_die():
	queue_free()
	GlobalEvents.emit_signal("enemy_die",self)

func shoot():
	set_new_state(CanonRexStateMachine.STATE_SHOOTING)

func damage():
	set_new_state(CanonRexStateMachine.STATE_DAMAGED)
	life -=1
	if life <=0:
		die()


func spawn_fireball():
	var newFireBall=FireBall.instantiate()
	add_child(newFireBall)
	newFireBall.global_position=spawnFireBall.global_position
	newFireBall.set_vector(moveVector)
	print('spawn fire ball')
	pass
 

func get_current_state()->PlayerState:
	return _state_machine.current_state
	
func set_new_state(new_state):
	current_state_name=new_state
	_state_machine.set_state(new_state)
	#print("new state:"+new_state)


func _on_timer_timeout():
	shoot()
	pass # Replace with function body
	
func disable():
	shootTimer.stop()
	pass
	
func enable():
	shootTimer.start()

	pass

func turn():
	_sprite.flip_h=true
	spawnFireBall.position.x=33
	shoot()
	shootTimer.stop()
	shootTimer.wait_time=3
	shootTimer.start()
	moveVector=Vector2(INPULSE_RIGHT,0)

func turnBack():
	_sprite.flip_h=false
	spawnFireBall.position.x=-33
	shootTimer.stop()
	shootTimer.wait_time=10
	shootTimer.start()
	moveVector=Vector2(INPULSE_LEFT,0)


func _on_area_2d_body_entered(body):
	if body is Player or body is Sheep:
		turn()
	pass # Replace with function body.


func _on_area_2d_body_exited(body):
	if body is Player or body is Sheep:
		turnBack()
	pass # Replace with function body.
