extends Node2D

@onready var player:Player=$Player
@onready var sheep:Sheep=$Sheep

@onready var hud=$HUD


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GlobalPlayer.set_actor(player)
	
	hud.set_score(GlobalPlayer.get_score())
	hud.set_water(GlobalPlayer.get_water())
	hud.set_player_life(GlobalPlayer.get_life())
	hud.set_sheep_life(GlobalSheep.get_life())
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
