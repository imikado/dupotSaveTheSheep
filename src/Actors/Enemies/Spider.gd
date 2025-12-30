extends Enemy
class_name Spider

@onready var _sprite=$Sprite2D

@onready var _state_machine:CanonRexStateMachine = $StateMachine

@export var FireBall:PackedScene

@onready var spawnFireBall:Marker2D=$Marker2D
@onready var shootTimer:Timer=$Timer


const INPULSE_BOTTOM=-25
const INPULSE_RIGHT=70

const LIFE_DAMAGED=10

var life =100

var current_state_name=""
var moveVector=Vector2(0,INPULSE_BOTTOM)



func die():
	_alive=false
	set_new_state(CanonRexStateMachine.STATE_DIE)
		
func finish_die():
	queue_free()
	GlobalEvents.emit_signal("enemy_die",self)

func shoot():
	if _alive:
		set_new_state(CanonRexStateMachine.STATE_SHOOTING)

func damage():
	if _alive:
		life -=LIFE_DAMAGED
		GlobalEvents.enemy_spider_health_changed.emit(life)
		if life <=0:
			die()
		else:
			set_new_state(CanonRexStateMachine.STATE_DAMAGED)


func spawn_fireball():
	var newFireBall=FireBall.instantiate()
	get_parent().add_child(newFireBall)
	newFireBall.global_position=spawnFireBall.global_position
	#newFireBall.set_vector(moveVector)
	print('spawn fire ball')


func get_current_state()->PlayerState:
	return _state_machine.current_state

	
func set_new_state(new_state):
	current_state_name=new_state
	_state_machine.set_state(new_state)
	#print("new state:"+new_state)


func _on_timer_timeout():
	shoot()
	shootTimer.start()
	pass # Replace with function body
	
func disable():
	shootTimer.stop()
	pass
	
func enable():
	shootTimer.start()

	pass

 
 
