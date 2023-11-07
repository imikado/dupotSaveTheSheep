extends Camera2D

@export var move_speed = 0.5  # camera position lerp speed
@export var zoom_speed = 0.25  # camera zoom lerp speed
@export var min_zoom = 1.5  # camera won't zoom closer than this
@export var max_zoom = 5  # camera won't zoom farther than this
@export var margin = Vector2(400, 200)  # include some buffer area around targets

@onready var player=$"../LevelTemplate/LevelWorld/Player"
@onready var sheep=$"../LevelTemplate/LevelWorld/Sheep"

@onready var targets = []  # Array of targets to be tracked.

@onready var screen_size = get_viewport_rect().size

var margin_actor=120

func _ready():
	
	add_target(sheep)
	add_target(player)

func _process(delta):
	var min_x=0
	var min_y=0
	
	var max_x=0
	var max_y=0
	
	var delta_x=0
	var delta_y=0
	
	var camera_x=0
	var camera_y=0
	
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
	
	var zoom_x=clamp(get_viewport_rect().size.x/(max_x-min_x),0.2,1)
	
	zoom_x=zoom_x
	
	zoom=Vector2(zoom_x,zoom_x)

func off_process(delta):
	if !targets:
		return
	# Keep the camera centered between the targets
	var p = Vector2.ZERO
	for target in targets:
		p += target.position
	p /= targets.size()
	position = lerp(position, p, move_speed)
	# Find the zoom that will contain all targets
	var r = Rect2(position, Vector2.ONE)
	for target in targets:
		r = r.expand(target.position)
	r = r.grow_individual(margin.x, margin.y, margin.x, margin.y)
	var d = max(r.size.x, r.size.y)
	var z
	if r.size.x > r.size.y * screen_size.aspect():
		z = clamp(r.size.x / screen_size.x, min_zoom, max_zoom)
	else:
		z = clamp(r.size.y / screen_size.y, min_zoom, max_zoom)
	zoom = lerp(zoom, Vector2.ONE * z, zoom_speed)

func add_target(t):
	if not t in targets:
		targets.append(t)

func remove_target(t):
	if t in targets:
		targets.erase(t)
