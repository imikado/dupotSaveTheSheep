extends Node2D

@onready var anim:AnimationPlayer=$AnimationPlayer

@onready var panelAnim:AnimationPlayer=$panel_key/AnimationPlayer
@onready var panel:Sprite2D=$panel_key/PanelKey

@onready var sheepPanelAnim:AnimationPlayer=$panel_sheep/AnimationPlayer
@onready var sheepPanel:Sprite2D=$panel_sheep/panel

var _opened:bool=false
var _hasSheep:bool=false
var _pendingSheep:Sheep=null

func _ready() -> void:
	anim.play("idle")
	hide_panel()
	hide_sheep_panel()

func hide_panel():
	panel.visible=false
	
func display_panel():
	panel.visible=true
	panelAnim.play("display")

func open_elevator():
	if _opened:
		return
	_opened=true
	anim.play("opened")

func _on_lock_area_2d_body_entered(body: Node2D) -> void:
	if body is Player: 
		if body.has_key():
			open_elevator()
		else:
			display_panel()
	pass # Replace with function body.


func hide_sheep_panel():
	sheepPanel.visible=false
	
func display_sheep_panel():
	sheepPanel.visible=true
	sheepPanelAnim.play("display_sheep")

func check_elevator():
	if _pendingSheep != null:
		sheep_enter(_pendingSheep)

func sheep_enter(sheep:Sheep):
	_hasSheep=true
	sheep.queue_free()

func _on_gate_area_2d_body_entered(body: Node2D) -> void:
	if body is Sheep:
		if !_opened:
			body.stop()
			_pendingSheep=body
		else:
			sheep_enter(body)
			
	if !_opened:
		return
		
	if body is Player:
		if _hasSheep:
			body.queue_free()
			print('END')
		else:
			display_sheep_panel()
			
	pass # Replace with function body.
