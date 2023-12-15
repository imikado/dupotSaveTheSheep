extends Node2D

@onready var _subBridgeAnimation:AnimationPlayer=$SubBridgeAnimationPlayer

@onready var _subBridge:StaticBody2D=$subBridge
@onready var _subBridgetParts:Node2D=$subBridge/parts
@onready var _subBridgeToDuplicate:StaticBody2D= $toDuplicate/subBridge

@export var _number_subBridge:int=0
@export var _camera_enabled:bool=true

@onready var _camera:Camera2D=$Camera2D

var is_open=true

var init=false

var _available=true

# Called when the node enters the scene tree for the first time.
func _ready():
	
	if ! _camera_enabled:
		_camera.queue_free()
	
	
	for i in range(0,_number_subBridge):
		var new_sub_bridge=_subBridgeToDuplicate.duplicate()
		
		_subBridgetParts.add_child(new_sub_bridge)
		
		new_sub_bridge.visible=true
		new_sub_bridge.global_position=_subBridge.global_position
	
	#open()
	
	#close()
	pass # Replace with function body.

func open():
	if(!_available):
		return
	_available=false
	_subBridgeAnimation.play("open")
	
	is_open=true


func sub_close():
	if init:
		_available=true
		return
		
	
	var number=0
	var tween = get_tree().create_tween()
		
	for child in _subBridgetParts.get_children():
		number+=1
		tween.tween_property(child,'position', child.position+Vector2(-26*number,0.0),0.5).set_trans(Tween.TRANS_BACK)
	
	tween.connect("finished",bridge_tween_closed)
	
	
func bridge_tween_closed():
	init=true
	_available=true
	print('fini ouvrir')
	
	
func sub_open():
	_available=true
	return
		
	
func close():
	if(!_available):
		return
	_available=false
	_subBridgeAnimation.play("close")
	
	is_open=false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

