extends Camera2D

@export var move_speed = 0.5  # camera position lerp speed
@export var zoom_speed = 0.25  # camera zoom lerp speed
@export var min_zoom = 1.3  # camera won't zoom closer than this
@export var max_zoom = 7  # camera won't zoom farther than this
@export var player:Player
@export var sheep:Sheep

@onready var targets = []  # Array of targets to be tracked.

@onready var screen_size = get_viewport_rect().size

var margin_actor=120

func _ready():
	
	add_target(sheep)
	add_target(player)

func _process(_delta):
	var min_x=0
	var min_y=0
	
	var max_x=0
	var max_y=0
	
	var delta_x=0
	var delta_y=0
	
	if sheep!=null and player!=null:
		if  sheep.global_position.x < player.global_position.x:
			min_x=sheep.global_position.x
			max_x=player.global_position.x
		else:
			max_x=sheep.global_position.x
			min_x=player.global_position.x
			
			
		if  sheep.global_position.y > player.global_position.y:
			min_y=sheep.global_position.y
			max_y=player.global_position.y
		else:
			max_y=sheep.global_position.y
			min_y=player.global_position.y
		
		min_x-=margin_actor
		max_x+=margin_actor
		
		min_y+=margin_actor
		max_y-=margin_actor
		
		delta_x=(max_x-min_x)/2
		delta_y=(max_y-min_y)/2
		
		position.x=min_x+delta_x
		position.y=min_y+delta_y
	
		var zoom_x=clamp(get_viewport_rect().size.x/(max_x-min_x),0.3,1)
		
		var zoom_y=clamp(get_viewport_rect().size.y/(min_y-max_y),0.3,1)
		
		if zoom_x < zoom_y:
			zoom=Vector2(zoom_x,zoom_x)
		else:
			zoom=Vector2(zoom_y,zoom_y)
	elif player!=null:
		zoom=Vector2(1,1)
		position=player.global_position
	elif sheep!=null:
		zoom=Vector2(1,1)
		position=sheep.global_position
		 


func add_target(t):
	if not t in targets:
		targets.append(t)

func remove_target(t):
	if t in targets:
		targets.erase(t)
