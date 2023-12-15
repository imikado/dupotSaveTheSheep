extends AnimatableBody2D

@onready var _animatedSprite = $AnimatedSprite2D

@export var distance:Vector2
@export var phase_time:float = 6.0

var start_position=Vector2.ZERO
var end_position=Vector2.ZERO



# Called when the node enters the scene tree for the first time.
func _ready():
	_animatedSprite.play()
	
	start_position=position
	end_position=start_position+distance

	start_tween()
	
func start_tween():
	var tween = get_tree().create_tween()
	tween.tween_property(self,'position',  end_position,phase_time)
	tween.tween_property(self,'position',  start_position,phase_time)
	tween.finished.connect(start_tween)
