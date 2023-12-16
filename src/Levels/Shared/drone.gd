extends AnimatableBody2D

@onready var _animatedSprite = $AnimatedSprite2D

@export var distance:Vector2
@export var phase_time:float = 6.0

var start_position=Vector2.ZERO
var end_position=Vector2.ZERO

var enabled=false
var running=false

func enable():
	enabled=true
	start_tween()
	
func disable():
	enabled=false

# Called when the node enters the scene tree for the first time.
func _ready():
	_animatedSprite.play()
	
	start_position=position
	end_position=start_position+distance
	
func start_tween():
	if running:
		return
	running=true
	var tween = get_tree().create_tween()
	tween.tween_property(self,'position',  end_position,phase_time)
	tween.tween_property(self,'position',  start_position,phase_time)
	tween.finished.connect(end_tween)
	#print('drone, start tween')

func end_tween():
	running=false
	if !enabled:
		return
	start_tween()
