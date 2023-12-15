extends TextureButton

@export var _export_label:String="default"

@onready var _uiLabel:= $Label


# Called when the node enters the scene tree for the first time.
func _ready():
	_uiLabel.text=_export_label
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
