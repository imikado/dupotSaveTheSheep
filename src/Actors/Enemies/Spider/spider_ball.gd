extends RigidBody2D

@onready var animatedSprite: AnimatedSprite2D = $AnimatedSprite2D

var _moveVector: Vector2 = Vector2.ZERO

# Called when the node enters the scene tree for the first time.
func _ready():
	animatedSprite.play()

func set_vector(moveVector: Vector2):
	_moveVector = moveVector
	#apply_central_force(moveVector)
	

func _physics_process(delta):
	apply_impulse(_moveVector * delta)

func _on_timer_timeout():
	queue_free()


func _on_area_2d_body_entered(body):
	if body is Player or body is Sheep:
		body.hit_damage(5)
		queue_free()
