extends Node2D


@onready var hud=$HUD

var score:int=0

# Called when the node enters the scene tree for the first time.
func _ready():	
	GlobalEvents.connect("enemy_die",on_enemy_die)
	
func on_enemy_die(enemy):
	score+=enemy.get_points()
	hud.set_score(score)
