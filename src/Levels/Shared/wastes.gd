extends Area2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


func _on_body_entered(body):
	print(body)
	if body is Player:
		GlobalEvents.player_gameover.emit()
	if body is Enemy and body.has_method('die'):
		body.die()
		
	pass # Replace with function body.
