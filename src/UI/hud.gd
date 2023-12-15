extends CanvasLayer

@onready var scoreLabel:Label=$scoreLabel

@onready var playerProgressBar:ProgressBar=$Player/lifeBar
@onready var sheepProgressBar:ProgressBar=$Sheep/lifeBar
@onready var waterProgressBar:ProgressBar=$Water/lifeBar


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func set_score(newscore:int):
	scoreLabel.text=str(newscore)

func set_water(value):
	waterProgressBar.value=value

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
