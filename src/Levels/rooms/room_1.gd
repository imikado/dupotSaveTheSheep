extends RoomAbstract

@onready var canonRex:CanonRex=$decor/CanonRex

@onready var _decor:Node2D=$decor

func _ready():
	set_decor_visible(false)

func set_decor_visible(state):
	_decor.visible=state

func _on_visible_on_screen_notifier_2d_screen_entered():
	set_decor_visible(true)
	if canonRex!=null and canonRex.has_method('enable'):
		canonRex.enable()


func _on_visible_on_screen_notifier_2d_screen_exited():
	set_decor_visible(false)
	if canonRex!=null and canonRex.has_method('disable'):
		canonRex.disable()
