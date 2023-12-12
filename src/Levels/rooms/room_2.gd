extends Node2D

@onready var width=$ColorRect.get_rect().size.x

@onready var _enemyList=$enemyList

@onready var _spawnTimer=$Timer

@onready var _spawnMarker2D=$spawnMarker2D

@onready var TRex=load("res://src/Actors/Enemies/TRex.tscn")

func _ready():
	spawn_trex()	
	
func spawn_trex():
	
	var enemyNumber=_enemyList.get_child_count()
	
	if enemyNumber < 2: 
	
		var new_TRex=TRex.instantiate()
		
		_enemyList.add_child(new_TRex)
		
		new_TRex.global_position=_spawnMarker2D.global_position


	_spawnTimer.start()
	


func _on_timer_timeout():
	spawn_trex()
	pass # Replace with function body.
