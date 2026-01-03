extends Node2D

@export var NextLevel: PackedScene
@export var gameOverScene: PackedScene


@onready var hud = $HUD

@onready var player: Player = $SubViewportContainer/SubViewport/Player
@onready var sheep: Sheep = $SubViewportContainer2/SubViewport/Sheep

@onready var subviewPortMain = $SubViewportContainer/SubViewport
@onready var subViewPortSheep = $SubViewportContainer2/SubViewport


var gameover = false


const DISTANCE_TO_PLAYER_X = 230
const DISTANCE_TO_PLAYER_Y = 60


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var world = subviewPortMain.find_world_2d()
	subViewPortSheep.world_2d = world

	GlobalGame.saveLevel(2)

	GlobalPlayer.set_actor(player)
	
	GlobalEvents.player_take_damage.connect(on_player_take_damage)

	GlobalEvents.sheep_take_damage.connect(on_sheep_take_damage)

	GlobalEvents.player_increase_life.connect(on_player_increase_life)
	
	GlobalEvents.player_take_water_bottle.connect(on_player_take_water_bottle)

	GlobalEvents.player_water_changed.connect(on_player_water_changed)

	GlobalEvents.enemy_die.connect(on_enemy_die)
	
	GlobalEvents.get_key.connect(on_get_key)

	GlobalEvents.end_level.connect(on_end_level)
	
	GlobalGame.saveLevelPlayerLife(GlobalPlayer.get_life())
	GlobalGame.saveLevelSheepLife(GlobalSheep.get_life())
	GlobalGame.saveLevelWaterValue(GlobalPlayer.get_water())
	GlobalGame.saveLevelScore(GlobalPlayer.get_score())
	
	hud.set_score(GlobalPlayer.get_score())
	hud.set_water(GlobalPlayer.get_water())
	hud.set_player_life(GlobalPlayer.get_life())
	hud.set_sheep_life(GlobalSheep.get_life())

	#player.position.x += 1600
	#player.position.y -= 400
	#sheep.position = player.position + Vector2(300, -50)

	hud.disableProgression()

	pass # Replace with function body.


func _process(_delta: float) -> void:
	if sheep != null and player != null and (abs(sheep.global_position.x - player.global_position.x) > DISTANCE_TO_PLAYER_X or abs(sheep.global_position.y - player.global_position.y) > DISTANCE_TO_PLAYER_Y):
		$SubViewportContainer2.visible = true
		$ColorRect.visible = true
	else:
		$SubViewportContainer2.visible = false
		$ColorRect.visible = false

func on_get_key():
	hud.enable_key()

func on_enemy_die(enemy):
	GlobalPlayer.increase_score(enemy.get_points())
	hud.set_score(GlobalPlayer.get_score())
	
func on_player_water_changed(new_value):
	hud.set_water(new_value)

func on_player_take_water_bottle(water_value):
	player.take_water(water_value)

func on_player_take_damage(damage):
	GlobalPlayer.decrease_life(damage)
	hud.set_player_life(GlobalPlayer.get_life())
	if GlobalPlayer.get_life() <= 0:
		on_player_gameover()


func on_player_increase_life(value):
	GlobalPlayer.increase_life(value)
	hud.set_player_life(GlobalPlayer.get_life())
	

func on_sheep_take_damage(damage):
	GlobalSheep.decrease_life(damage)
	hud.set_sheep_life(GlobalSheep.get_life())
	if GlobalSheep.get_life() <= 0:
		on_player_gameover()

func on_player_gameover():
	if !gameover:
		print("game over level")
		gameover = true
		get_tree().change_scene_to_packed(gameOverScene)
	

func _on_label_button_button_down():
	on_player_gameover()
	pass # Replace with function body.


func _on_timer_timeout():
	on_player_gameover()
	pass # Replace with function body.


func on_end_level():
	GlobalPlayer.increase_score(100)

	var screenshotImage = get_viewport().get_texture().get_image()
	var screenshotTexture = ImageTexture.create_from_image(screenshotImage)

	GlobalGame.set_last_screenshot(screenshotTexture)
	GlobalTransition.change_scene_to_packed(NextLevel)
