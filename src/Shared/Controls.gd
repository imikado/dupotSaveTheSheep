extends CanvasLayer

func _ready() -> void:
	if(!GlobalGame.isControlsEnabled()):
		visible=false


func _on_jump_pressed():
	GlobalInput.press_jump_button()

func _on_attack_pressed():
	GlobalInput.press_attack_button()

func _on_action_pressed():
	GlobalInput.press_action_button()

