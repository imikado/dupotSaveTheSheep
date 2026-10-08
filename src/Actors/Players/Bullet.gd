extends RigidBody2D

var vect=Vector2.ZERO

var direction=0

@onready var _sprite2d=$Sprite2D

const SPEED=220
const LIFETIME=0.7

func run(new_direction):
	$AnimationPlayer.play("default")
	direction=new_direction
	if direction==-1:
		_sprite2d.flip_h=true
		
	await get_tree().create_timer(LIFETIME).timeout
	if is_inside_tree():
		Fx.burst(get_parent(), global_position, Fx.COLOR_WATER, 4, 20.0)
		queue_free()

func _physics_process(delta):
	var collidedCollisionBody=move_and_collide(Vector2(SPEED*delta*direction,0.1))
	
	if collidedCollisionBody:
		var collidedActor=collidedCollisionBody.get_collider()
		if collidedActor is Enemy:
			collidedActor.damage()
			
		Fx.splash(get_parent(), global_position)
		queue_free()
