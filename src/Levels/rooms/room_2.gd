extends Node2D

@onready var width=$ColorRect.get_rect().size.x

@onready var _enemyList=$enemyList

@onready var _spawnTimer=$Timer

@onready var _spawnMarker2D=$spawnMarker2D

@export var TRex:PackedScene

var enabled=false
	
func spawn_trex():
	
	var enemyNumber=_enemyList.get_child_count()
	
	if enemyNumber < 2: 
	
	
		var new_TRex=TRex.instantiate()
		
		_enemyList.add_child(new_TRex)
		
		new_TRex.global_position=_spawnMarker2D.global_position


	_spawnTimer.start()
	


func _on_timer_timeout():
	if is_enabled():
		spawn_trex()
	
func is_enabled()->bool:
	return enabled

func _on_visible_on_screen_notifier_2d_screen_entered():
	if !is_enabled():
		spawn_trex()
		enable_enemy_list()

func _on_visible_on_screen_notifier_2d_screen_exited():
	disable_enemy_list()
	
func disable_enemy_list():
	enabled=false
	set_enemy_physics_process(false)

func enable_enemy_list():
	enabled=true
	set_enemy_physics_process(true)
	
	
func set_enemy_physics_process(processEnabled:bool):
	for enmyLoop:Enemy in _enemyList.get_children():
		enmyLoop.set_physics_process(processEnabled)

