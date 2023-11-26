extends CanvasLayer

@onready var scoreLabel:Label=$scoreLabel

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func set_score(newscore:int):
	scoreLabel.text=str(newscore)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
