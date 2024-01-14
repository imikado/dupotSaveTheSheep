extends Area2D

@onready var _animationPlayer=$AnimationPlayer

@export var bridge:Node2D

# Called when the node enters the scene tree for the first time.
func _ready():
	#_animationPlayer.play('open')
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func off_process(_delta):
	for area in get_overlapping_areas():
		if area.name == Player.AREA and GlobalInput.is_press_action_button():
			GlobalPlayer.get_actor().action()

func remote_open():
	bridge.open()

func remote_close():
	bridge.close()

func action():
	if bridge.is_open():
		_animationPlayer.play('close')
	else:
		_animationPlayer.play('open')


func _on_body_entered(body):
	if body is Player:
		body.set_pending_action(self)


func _on_body_exited(body):
	if body is Player:
		body.reset_pending_action()
