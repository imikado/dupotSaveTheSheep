extends RigidBody2D

@onready var animatedSprite:AnimatedSprite2D=$AnimatedSprite2D

func _ready() -> void:
	animatedSprite.play()



func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		GlobalEvents.get_key.emit()
		queue_free()
		body.get_key()
	pass # Replace with function body. # Replace with function body.
