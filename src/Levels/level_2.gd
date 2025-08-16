extends Node2D

@onready var hud = $HUD

@onready var player: Player = $SubViewportContainer/SubViewport/Player
@onready var sheep: Sheep = $SubViewportContainer2/SubViewport/Sheep

@onready var subviewPortMain = $SubViewportContainer/SubViewport
@onready var subViewPortSheep = $SubViewportContainer2/SubViewport

const DISTANCE_TO_PLAYER_X = 230
const DISTANCE_TO_PLAYER_Y = 60


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var world = subviewPortMain.find_world_2d()
	subViewPortSheep.world_2d = world

	GlobalPlayer.set_actor(player)
	
	hud.set_score(GlobalPlayer.get_score())
	hud.set_water(GlobalPlayer.get_water())
	hud.set_player_life(GlobalPlayer.get_life())
	hud.set_sheep_life(GlobalSheep.get_life())

	#player.position.x += 1600
	#player.position.y += 400
	#sheep.position = player.position + Vector2(-20, 0)


	pass # Replace with function body.


func _process(_delta: float) -> void:
	if sheep != null and player != null and (abs(sheep.global_position.x - player.global_position.x) > DISTANCE_TO_PLAYER_X or abs(sheep.global_position.y - player.global_position.y) > DISTANCE_TO_PLAYER_Y):
		$SubViewportContainer2.visible = true
		$ColorRect.visible = true
	else:
		$SubViewportContainer2.visible = false
		$ColorRect.visible = false