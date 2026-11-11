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

# Two players mode: the camera follows the middle of both players, who cannot
# get further apart than the screen
const PLAYER2_SCENE = preload("res://src/Actors/Players/Player2.tscn")
const PLAYER2_SPAWN_OFFSET = Vector2(-26, 0)
const MAX_PLAYERS_DISTANCE_X = 400.0

var player2: Player = null
var _camera: Camera2D = null
var _camera_offset := Vector2.ZERO


func _ready() -> void:
	var world = subviewPortMain.find_world_2d()
	subViewPortSheep.world_2d = world

	GlobalPlayer.set_actor(player)
	GlobalInput.set_two_players(GlobalGame.is_two_players())
	if GlobalGame.is_two_players():
		# A player down in the previous level is back
		GlobalPlayer.revive_downed()
		# Deferred: the level places player 1 after this _ready
		_spawn_player2.call_deferred()
	GlobalAudio.play_music("level")

	GlobalEvents.player_gameover.connect(on_player_gameover)
	GlobalEvents.enemy_die.connect(on_enemy_die)
	GlobalEvents.player_water_changed.connect(on_player_water_changed)
	GlobalEvents.player_take_damage.connect(on_player_take_damage)
	GlobalEvents.sheep_take_damage.connect(on_sheep_take_damage)
	GlobalEvents.player_increase_life.connect(on_player_increase_life)
	GlobalEvents.end_level.connect(on_end_level)

	hud.set_score(GlobalPlayer.get_score())
	hud.set_water(GlobalPlayer.get_water())
	hud.set_player_life(GlobalPlayer.get_life())
	if GlobalGame.is_two_players():
		hud.enable_second_player()
		hud.set_player_life(GlobalPlayer.get_life(2), 2)
	hud.set_sheep_life(GlobalSheep.get_life())


func _spawn_player2() -> void:
	player2 = PLAYER2_SCENE.instantiate()
	player2.player_index = 2
	player2.z_index = player.z_index
	player2.z_as_relative = player.z_as_relative
	subviewPortMain.add_child(player2)
	player2.global_position = player.global_position + PLAYER2_SPAWN_OFFSET
	# Players walk through each other
	player2.add_collision_exception_with(player)
	player.add_collision_exception_with(player2)
	GlobalPlayer.add_actor(player2)

	_camera = player.get_node_or_null("Camera2D")
	if _camera != null:
		_camera_offset = _camera.position
		_camera.top_level = true
		_camera.global_position = _players_center() + _camera_offset
		_camera.reset_smoothing()


func _players_center() -> Vector2:
	var actors := GlobalPlayer.get_actors()
	var center := Vector2.ZERO
	for actorLoop in actors:
		center += actorLoop.global_position
	return center / max(actors.size(), 1)


func _physics_process(_delta: float) -> void:
	if player2 == null:
		return
	var actors := GlobalPlayer.get_actors()
	for actorLoop in actors:
		if actorLoop._dying:
			# The camera stays still so the player drops out of the screen
			return
	if actors.size() == 2:
		var center_x := _players_center().x
		for actorLoop in actors:
			actorLoop.global_position.x = clamp(actorLoop.global_position.x, center_x - MAX_PLAYERS_DISTANCE_X / 2, center_x + MAX_PLAYERS_DISTANCE_X / 2)
	if is_instance_valid(_camera) and !actors.is_empty():
		_camera.global_position = _players_center() + _camera_offset


# Player nearest to the sheep (player 1 out of two players mode)
func _nearest_player() -> Player:
	var nearest: Player = null
	for actorLoop in GlobalPlayer.get_actors():
		if nearest == null or (is_instance_valid(sheep) and actorLoop.global_position.distance_to(sheep.global_position) < nearest.global_position.distance_to(sheep.global_position)):
			nearest = actorLoop
	return nearest


func _process(_delta: float) -> void:
	var nearest = _nearest_player()
	if sheep != null and nearest != null and (abs(sheep.global_position.x - nearest.global_position.x) > DISTANCE_TO_PLAYER_X or abs(sheep.global_position.y - nearest.global_position.y) > DISTANCE_TO_PLAYER_Y):
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


func on_player_take_damage(damage, index := 1):
	GlobalPlayer.decrease_life(damage, index)
	GlobalPlayer.update_life(max(GlobalPlayer.get_life(index), 0), index)
	hud.set_player_life(GlobalPlayer.get_life(index), index)
	if GlobalPlayer.get_life(index) <= 0:
		on_player_out_of_life(index)


# Two players mode: the player is down while the other one carries on,
# game over once nobody is left
func on_player_out_of_life(index):
	var actor: Player = player2 if index == 2 else player
	if GlobalGame.is_two_players() and is_instance_valid(actor):
		actor.down()
		var others := GlobalPlayer.get_actors()
		if !others.is_empty():
			hud.player = others[0]
			hud.show_banner("PLAYER %d DOWN" % index, "BACK AT THE NEXT LEVEL", Player.COOP_COLORS[index])
			return
	on_player_gameover()


func on_player_increase_life(value, index := 1):
	GlobalPlayer.increase_life(value, index)
	hud.set_player_life(GlobalPlayer.get_life(index), index)


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
