extends Node2D
class_name World

@onready var tile_map:TileMap=$ground

@onready var _spawnList=$spawnList
@onready var _enemyList=$enemyList

static var _instance: World = null

@onready var TRex=load("res://src/Actors/Enemies/TRex.tscn")

@onready var spawnTimer:Timer=$spawnTimer

func _ready():
	_instance = self if _instance == null else _instance

	spawn_trex()	
	
func spawn_trex():
	
	var spawnNumber=_spawnList.get_child_count()
	var enemyNumber=_enemyList.get_child_count()
	
	if enemyNumber < spawnNumber*2: 
		for child in _spawnList.get_children():
			var new_TRex=TRex.instantiate()
			
			_enemyList.add_child(new_TRex)
			
			new_TRex.global_position=child.global_position


	spawnTimer.start()
	
static func get_tile_data_at(position: Vector2) -> TileData:
	var local_position: Vector2i = _instance.tile_map.local_to_map(position)
	return _instance.tile_map.get_cell_tile_data(0, local_position)


static func get_custom_data_at(position: Vector2, custom_data_name: String, defaultValue:Variant) -> Variant:
	var data = get_tile_data_at(position)
	if data == null:
		return defaultValue
	return data.get_custom_data(custom_data_name)



func _on_spawn_timer_timeout():
	spawn_trex()
	
	
