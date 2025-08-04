class_name Room3 extends RoomAbstract


@onready var drone = $decor/drone

@onready var _decor: Node2D = $decor

var enabled = false

const SCENE: PackedScene = preload("res://src/Levels/Level1/rooms/room_3.tscn")

static func create() -> Room3:
	var room = SCENE.instantiate()
	return room

func _ready():
	set_decor_visible(false)
	set_drone_process(false)

func set_decor_visible(state):
	_decor.visible = state

func _on_visible_on_screen_notifier_2d_screen_entered():
	set_decor_visible(true)
	enabled = true
	set_drone_process(enabled)

func _on_visible_on_screen_notifier_2d_screen_exited():
	set_decor_visible(false)
	enabled = false
	set_drone_process(enabled)

func set_drone_process(processEnabled):
	if processEnabled:
		drone.enable()
	else:
		drone.disable()
