extends Node

const START_SCORE = 0
const MAX_WATER = 80
const MAX_LIFE=100
# Two players mode: a player down comes back at the next level with this life
const REVIVE_LIFE=50

var _score = 0
var _life = GlobalGame.player_start_life
var _life2 = GlobalGame.player_start_life
var _water = GlobalGame.player_start_water
var _level = 1

var _player:Player
var _players:Array[Player] = []

func set_actor(player_:Player):
	_player=player_
	_players = [player_]

func get_actor()->Player:
	return _player

func add_actor(player_:Player):
	if not player_ in _players:
		_players.append(player_)

# Players still in the level (a player leaves it on the motorbike, or is down)
func get_actors()->Array[Player]:
	var list:Array[Player] = []
	for playerLoop in _players:
		if is_instance_valid(playerLoop) and playerLoop.is_inside_tree() and !playerLoop.is_down():
			list.append(playerLoop)
	return list

func set_level(level):
	_level = level


func get_level():
	return _level


func reset_game():
	_level = 1
	_score = START_SCORE
	_life = GlobalGame.player_start_life
	_life2 = GlobalGame.player_start_life
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


func set_water(value):
	_water = value


func use_amount_water(value):
	_water -= value


func can_use_amount_water(value):
	if _water >= value:
		return true
	return false


# index: 1 for player 1, 2 for player 2 (two players mode)
func get_life(index := 1):
	return _life2 if index == 2 else _life


func decrease_life(value, index := 1):
	update_life(get_life(index) - value, index)


func increase_life(value, index := 1):
	update_life(min(get_life(index) + value, MAX_LIFE), index)

func update_life(value, index := 1):
	if index == 2:
		_life2 = value
	else:
		_life = value

func revive_downed():
	for index in [1, 2]:
		if get_life(index) <= 0:
			update_life(REVIVE_LIFE, index)
