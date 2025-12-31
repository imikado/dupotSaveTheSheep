extends Node2D

@onready var animation_player:AnimationPlayer= $animation
@onready var spider:Spider= $Spider
@onready var lifeBarBloc:Control = $Spider/lifeBar
@onready var lifeBar:ProgressBar= $Spider/lifeBar/lifeBar
@onready var timerHide:Timer=$TimerHideLifeBar

@onready var fireballSource:RigidBody2D=$Node2D/Fireball
 
var enabled:bool=false

var alive=true

func _ready() -> void:
	GlobalEvents.enemy_spider_health_changed.connect(on_enemy_spider_health_changed)
	GlobalEvents.enemy_spider_health_changed.emit(100)
	hide_lifebar()
	

		

func load_source():
	if(!alive):
		return
	animation_player.play('go_down')
	spider.disable()
	
func go_shooting():
	if(!alive):
		return
	animation_player.play('go_right')
	spider.enable()

func on_enemy_spider_health_changed(newValue:int):
	if(!alive):
		return
	lifeBar.value=newValue
	if(newValue<=0):
		animation_player.play("fireball_hide")
		alive=false
		return
	display_lifebar()


func remove_fireball_source():
	fireballSource.queue_free()

	
func _on_area_2d_body_entered(body: Node2D) -> void:
	if(!alive):
		return
	if body is Player:
		if !enabled:
			enabled=true;
			load_source()
			
	pass # Replace with function body.

func hide_lifebar()->void:
	if(!alive):
		return
	timerHide.stop()
	lifeBarBloc.visible=false

func display_lifebar()->void:
	if(!alive):
		return
	lifeBarBloc.visible=true
	timerHide.stop()
	timerHide.start()

func _on_timer_hide_life_bar_timeout() -> void:
	hide_lifebar()
	pass # Replace with function body.
