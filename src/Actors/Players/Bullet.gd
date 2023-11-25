extends RigidBody2D

var vect=Vector2.ZERO

var direction=0

@onready var _sprite2d=$Sprite2D

const SPEED=100

func run(new_direction):
	direction=new_direction
	if direction==-1:
		_sprite2d.flip_h=true
		
	await get_tree().create_timer(1.0).timeout
	queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var collidedCollisionBody=move_and_collide(Vector2(SPEED*delta*direction,0.1))
	
	if collidedCollisionBody:
		var collidedActor=collidedCollisionBody.get_collider()
		if collidedActor is Enemy:
			collidedActor.damage()
			
		queue_free()
	
