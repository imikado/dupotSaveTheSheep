extends Control

@onready var _menuButton:=$menuButton
@onready var _line:=$line
@onready var _table:=$ScrollContainer/table



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
	

const PODIUM_COLORS = [Color(1, 0.839216, 0.360784), Color(0.85, 0.87, 0.95), Color(0.85, 0.55, 0.3)]

func build(scoreList):
	
	var rank = 0
	for scoreLoop in scoreList:
		
		var newLine=_line.duplicate()
		newLine.get_node("row/rank").text=str(rank + 1) + "."
		newLine.get_node("row/date").text=scoreLoop.date;
		newLine.get_node("row/score").text=str(int( scoreLoop.score));
		newLine.visible=true

		if rank < PODIUM_COLORS.size():
			for label in newLine.get_node("row").get_children():
				label.add_theme_color_override("font_color", PODIUM_COLORS[rank])
		if rank % 2 == 1:
			newLine.self_modulate = Color(1, 1, 1, 0.5)
		
		_table.add_child(newLine)
		rank += 1
	
	_menuButton.grab_focus()

func _on_menu_button_pressed() -> void:
	get_tree().change_scene_to_file("res://src/UI/Screens/Menu.tscn")

	pass # Replace with function body.
