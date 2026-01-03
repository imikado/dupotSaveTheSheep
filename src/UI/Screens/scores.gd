extends Control

@onready var _menuButton:=$menuButton
@onready var _line:=$line
@onready var _table:=$ScrollContainer/table

@export var menuLevel: PackedScene


var scoreListOff=[
	{
		"date": "2023-03-24 08:00:00",
		"score":120
	},
	{
		"date": "2023-03-25 09:25:00",
		"score":35
	},
	{
		"date": "2023-03-24 08:00:00",
		"score":20
	},
	{
		"date": "2023-03-25 09:25:00",
		"score":35
	},
	{
		"date": "2023-03-24 08:00:00",
		"score":20
	},
	{
		"date": "2023-03-25 09:25:00",
		"score":35
	},
	{
		"date": "2023-03-24 08:00:00",
		"score":20
	},
	{
		"date": "2023-03-25 09:25:00",
		"score":35
	}
	,
	{
		"date": "2023-03-25 09:25:00",
		"score":35
	}
	,
	{
		"date": "2023-03-25 09:25:00",
		"score":35
	}
	,
	{
		"date": "2023-03-25 09:25:00",
		"score":35
	}
]



func sort_descending(a, b):
		if a['score'] > b['score']:
			return true
		return false

func _ready() -> void:
	var scoreList=GlobalGame.getHighScoreList()
	
	_line.visible=false
	#var scoreList=Game.getHighScoreList()
	
	scoreList.sort_custom(sort_descending)

	
	build(scoreList)
	

func build(scoreList):
	
	for scoreLoop in scoreList:
		
		var newLine=_line.duplicate()
		newLine.get_node("date").text=scoreLoop.date;
		newLine.get_node("score").text=str(scoreLoop.score);
		newLine.visible=true
		
		_table.add_child(newLine)
		
		print(scoreLoop)
	
	pass
	

func _on_menu_button_pressed() -> void:
	GlobalTransition.change_scene_to_packed(menuLevel)

	pass # Replace with function body.
