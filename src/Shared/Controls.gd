extends CanvasLayer

@export var joystick:=true
@export var jumpButton:=true
@export var attackButton:=true
@export var actionButton:=true

func _ready() -> void:
	if(!GlobalGame.isControlsEnabled()):
		visible=false
	
	$"joystick-big".visible=joystick
	$attack.visible=attackButton
	$jump.visible=jumpButton
	$action.visible=actionButton


func _on_jump_pressed():
	GlobalInput.press_jump_button()

func _on_attack_pressed():
	GlobalInput.press_attack_button()

func _on_action_pressed():
	GlobalInput.press_action_button()
