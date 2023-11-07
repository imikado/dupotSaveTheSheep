extends Node

@onready var players:={
	
	"player":{
		viewport= $HBoxContainer/SubViewportContainer/SubViewport,
		camera= $HBoxContainer/SubViewportContainer/SubViewport/Camera2D,
		player= $HBoxContainer/SubViewportContainer/SubViewport/LevelTemplate/LevelWorld/Player
		
	},
	"sheep":{
		viewport= $HBoxContainer/SubViewportContainer2/SubViewport,
		camera= $HBoxContainer/SubViewportContainer2/SubViewport/Camera2D,
		player= $HBoxContainer/SubViewportContainer/SubViewport/LevelTemplate/LevelWorld/Sheep
	}
	
}
@onready var fullViewportContainer=$SubViewportContainerFull
@onready var fullViewportViewport=$SubViewportContainerFull/SubViewport
@onready var fullViewportCamera=$SubViewportContainerFull/SubViewport/Camera2D

# Called when the node enters the scene tree for the first time.
func _ready():
	
	players["sheep"].viewport.world_2d=players["player"].viewport.world_2d
	for node in players.values():
		var remote_transform:=RemoteTransform2D.new()
		remote_transform.remote_path=node.camera.get_path()
		remote_transform.use_global_coordinates=true
		remote_transform.update_position=true
		remote_transform.update_scale=false
		node.player.add_child(remote_transform)
		
		
	
	fullViewportViewport.world_2d=players["player"].viewport.world_2d
	var remote_transform:=RemoteTransform2D.new()
	remote_transform.remote_path=fullViewportCamera.get_path()
	remote_transform.use_global_coordinates=true
	remote_transform.update_position=true
	remote_transform.update_scale=false
	players["player"].player.add_child(remote_transform)
	
	switchFull()
		
	
	
func switchFull():
	print('full')
	fullViewportContainer.visible=true
	fullViewportCamera.enabled=true
	
	
	pass
	
func switchSplit():
	print('split')
	fullViewportContainer.visible=false
	fullViewportCamera.enabled=true
	pass
		
	
func _process(delta):

	
	var zoom_delta=abs(players["player"].player.position.x - players["sheep"].player.position.x)/100  
	
	
	fullViewportCamera.zoom=Vector2( clamp(zoom_delta,0.2,1.0), clamp(zoom_delta,0.2,1.0) )
	return
	if (
		abs(players["player"].player.position.x - players["sheep"].player.position.x) < (512/2) 
		and 
		abs(players["player"].player.position.y - players["sheep"].player.position.y) < (25)
	):
		switchFull()
	else:
		switchSplit()
	
	pass
