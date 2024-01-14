extends Node2D

@onready var width=$ColorRect.get_rect().size.x

@onready var _enemyList=$enemyList

@onready var _spawnTimer=$Timer
@onready var _spawnStartTimer=$StartTimer

@onready var _spawnMarker2D=$spawnMarker2D

@export var TRex:PackedScene

@onready var door:Door=$Door

@onready var _spawnAlert:Sprite2D=$building/spawnAlert

var started=false

var enabled=false
	
func spawn_trex():
	
	var enemyNumber=_enemyList.get_child_count()
	
	if enemyNumber == 0: 

		var tween=create_tween()
		for i in range(2):
			tween.tween_property(_spawnAlert,"visible",true,0.3)
			tween.tween_property(_spawnAlert,"visible",false,0.3)
		

		tween.tween_property(_spawnAlert,"visible",false,0.6)

		await tween.finished
	
		door.open()
		await door.door_opened
	
		var new_TRex=TRex.instantiate()
		
		_enemyList.add_child(new_TRex)
		
		new_TRex.set_process(false)
		new_TRex.spawn()
		new_TRex.global_position=_spawnMarker2D.global_position
		new_TRex.set_process(true)



	_spawnTimer.start()
	



	
func is_enabled()->bool:
	return enabled

func _on_visible_on_screen_notifier_2d_screen_entered():
	if !is_enabled():
		if !started :
			_spawnStartTimer.start()
			started=true
		else:
			_spawnTimer.start()
		enable_enemy_list()

func _on_visible_on_screen_notifier_2d_screen_exited():
	disable_enemy_list()
	_spawnTimer.stop()
	
	
func disable_enemy_list():
	enabled=false
	#set_enemy_process(false)

func enable_enemy_list():
	enabled=true
	#set_enemy_process(true)
	
	
func set_enemy_process(processEnabled:bool):
	for enmyLoop:Enemy in _enemyList.get_children():
		enmyLoop.set_process(processEnabled)

func _on_timer_timeout():
	if is_enabled():
		print('timer 30s')
		spawn_trex()

func _on_start_timer_timeout():
	if is_enabled():
		print('timer 5s')
		spawn_trex()

