extends Node2D


@onready var hud=$HUD

var score:int=0

# Called when the node enters the scene tree for the first time.
func _ready():	
	GlobalEvents.connect("enemy_die",on_enemy_die)
	GlobalEvents.connect("player_water_changed",on_player_water_changed)
	
	hud.set_score(GlobalPlayer.get_score())
	hud.set_water(GlobalPlayer.get_water())
	
	
func on_enemy_die(enemy):
	score+=enemy.get_points()
	hud.set_score(score)
	
func on_player_water_changed(new_value):
	hud.set_water(new_value)
