extends Node

const START_SCORE = 0
const MAX_WATER = 80
const MAX_LIFE=100

var _score = 0
var _life = GlobalGame.player_start_life
var _water = GlobalGame.player_start_water
var _level = 1

var _player:Player

func set_actor(player_:Player):
	_player=player_

func get_actor()->Player:
	return _player

func set_level(level):
	_level = level


func get_level():
	return _level


func reset_game():
	_level = 1
	_score = START_SCORE
	_life = GlobalGame.player_start_life
	_water = GlobalGame.player_start_water


func get_score():
	return _score

func increase_score(value):
	_score+=value

func save_score(score):
	_score = score


func get_water():
	return _water


func increment_water(value):
	_water += value
	if _water > MAX_WATER:
		_water = MAX_WATER


func use_amount_water(value):
	_water -= value


func can_use_amount_water(value):
	if _water >= value:
		return true
	return false


func get_life():
	return _life


func decrease_life(value):
	_life -= value


func increase_life(value):
	_life += value
	if _life >= MAX_LIFE:
		_life=MAX_LIFE

func update_life(value):
	_life = value
