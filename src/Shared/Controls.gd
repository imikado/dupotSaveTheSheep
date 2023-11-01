extends CanvasLayer

@onready var _attackManaButton:=get_node("manaAttack")

func _ready() -> void:
	if(!GlobalGame.isControlsEnabled()):
		visible=false


func enable_mana_button():
	_attackManaButton.set_modulate(Color(1,1,1,1))

func disable_mana_button():
	_attackManaButton.set_modulate(Color(1,1,1,0.5))
	


func _on_jump_pressed():
	GlobalInput.press_jump_button()

func _on_attack_pressed():
	GlobalInput.press_attack_button()

func _on_action_pressed():
	GlobalInput.press_action_button()

