extends Area2D

@onready var _animationPlayer=$AnimationPlayer

@export var bridge:Node2D

var is_open=false

# Called when the node enters the scene tree for the first time.
func _ready():
	#_animationPlayer.play('open')
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	for area in get_overlapping_areas():
		if area.name == Player.AREA and GlobalInput.is_press_action_button():
			if bridge.is_open:
				_animationPlayer.play('close')
			else:
				_animationPlayer.play('open')
	pass

func remote_open():
	bridge.open()

func remote_close():
	bridge.close()


