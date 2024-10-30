extends Label

@export var state_machine:StateMachine

# Called when the node enters the scene tree for the first time.
func _ready():
	visible=GlobalGame.DEBUG_ENABLED
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	text=state_machine.current_state.name
	pass
