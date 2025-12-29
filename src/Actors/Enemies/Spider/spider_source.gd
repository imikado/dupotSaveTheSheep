extends RigidBody2D

@onready var animations:Node2D=$animations

func _ready() -> void:
	for animatedSprite:AnimatedSprite2D in animations.get_children():
		animatedSprite.play()
