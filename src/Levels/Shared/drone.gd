extends AnimatableBody2D

@onready var _animatedSprite = $AnimatedSprite2D

@export var distance:Vector2
@export var phase_time:float = 6.0

var start_position=Vector2.ZERO
var end_position=Vector2.ZERO

# Called when the node enters the scene tree for the first time.
func _ready():
	_animatedSprite.play()
	
	start_position=global_position
	end_position=start_position+distance
	
	var tween = get_tree().create_tween()
	tween.tween_property(self,'global_position',  end_position,phase_time)
	tween.tween_property(self,'global_position',  start_position,phase_time)
	tween.set_loops()
	
	#tween.tween_callback($this.queue_free)

