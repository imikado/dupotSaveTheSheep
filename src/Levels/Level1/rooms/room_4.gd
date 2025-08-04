class_name Room4 extends RoomAbstract


@onready var animationPlayer: AnimationPlayer = $decor/AnimationPlayer

@onready var _decor: Node2D = $decor

var opened = true

const SCENE: PackedScene = preload("res://src/Levels/Level1/rooms/room_4.tscn")

static func create() -> Room4:
	var room = SCENE.instantiate()
	return room

func _ready():
	set_decor_visible(false)
	
func set_decor_visible(state):
	_decor.visible = state

func open():
	print('open')
	opened = true
	animationPlayer.play_backwards("goup")


func is_open():
	return opened
	
func close():
	print('close')
	opened = false
	animationPlayer.play("goup")
	return


func _on_visible_on_screen_notifier_2d_screen_entered():
	set_decor_visible(true)
	pass # Replace with function body.


func _on_visible_on_screen_notifier_2d_screen_exited():
	set_decor_visible(false)
	pass # Replace with function body.
