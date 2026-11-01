extends Node2D
class_name LevelBase

@export var NextLevel: PackedScene
@export var gameOverScene: PackedScene

@onready var hud = $HUD

@onready var player: Player = $SubViewportContainer/SubViewport/Player
@onready var sheep: Sheep = $SubViewportContainer2/SubViewport/Sheep

@onready var subviewPortMain = $SubViewportContainer/SubViewport
@onready var subViewPortSheep = $SubViewportContainer2/SubViewport

var gameover = false
var _level_ended = false

const DISTANCE_TO_PLAYER_X = 230
const DISTANCE_TO_PLAYER_Y = 60


func _ready() -> void:
	var world = subviewPortMain.find_world_2d()
	subViewPortSheep.world_2d = world

	GlobalPlayer.set_actor(player)
	GlobalAudio.play_music("level")

	GlobalEvents.player_gameover.connect(on_player_gameover)
	GlobalEvents.enemy_die.connect(on_enemy_die)
	GlobalEvents.player_take_water_bottle.connect(on_player_take_water_bottle)
	GlobalEvents.player_water_changed.connect(on_player_water_changed)
	GlobalEvents.player_take_damage.connect(on_player_take_damage)
	GlobalEvents.sheep_take_damage.connect(on_sheep_take_damage)
	GlobalEvents.player_increase_life.connect(on_player_increase_life)
	GlobalEvents.end_level.connect(on_end_level)

	hud.set_score(GlobalPlayer.get_score())
	hud.set_water(GlobalPlayer.get_water())
	hud.set_player_life(GlobalPlayer.get_life())
	hud.set_sheep_life(GlobalSheep.get_life())


func _process(_delta: float) -> void:
	if sheep != null and player != null and (abs(sheep.global_position.x - player.global_position.x) > DISTANCE_TO_PLAYER_X or abs(sheep.global_position.y - player.global_position.y) > DISTANCE_TO_PLAYER_Y):
		$SubViewportContainer2.visible = true
		$ColorRect.visible = true
	else:
		$SubViewportContainer2.visible = false
		$ColorRect.visible = false


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
		gameover = true
		GlobalTransition.change_scene_to_packed(gameOverScene)


func _on_label_button_button_down():
	on_player_gameover()


func _on_timer_timeout():
	on_player_gameover()


func on_end_level():
	if _level_ended:
		return
	_level_ended = true

	var screenshotImage = get_viewport().get_texture().get_image()
	var screenshotTexture = ImageTexture.create_from_image(screenshotImage)

	GlobalGame.set_last_screenshot(screenshotTexture)
	GlobalTransition.change_scene_to_packed(NextLevel)
