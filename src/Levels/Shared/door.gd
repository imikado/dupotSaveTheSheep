extends Node2D
class_name Door

signal door_opened

@onready var animationPlayer=$AnimationPlayer

func _ready():
	animationPlayer.play("Closed")

func open():
	animationPlayer.play("Opening")
	pass

func emit_signal_opened():
	door_opened.emit()
  
