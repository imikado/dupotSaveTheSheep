extends Node2D
class_name World

@onready var tile_map:TileMap=$ground

static var _instance: World = null

func _ready():
	_instance = self if _instance == null else _instance
	
	
static func get_tile_data_at(position: Vector2) -> TileData:
	var local_position: Vector2i = _instance.tile_map.local_to_map(position)
	return _instance.tile_map.get_cell_tile_data(0, local_position)


static func get_custom_data_at(position: Vector2, custom_data_name: String, defaultValue:Variant) -> Variant:
	var data = get_tile_data_at(position)
	if data == null:
		return defaultValue
	return data.get_custom_data(custom_data_name)

