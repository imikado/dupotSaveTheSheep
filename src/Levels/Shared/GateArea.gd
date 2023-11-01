extends Area2D

signal gate_opened

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	for area in get_overlapping_areas():
		if area.name == Player.AREA:
			emit_signal("gate_opened")
	pass
