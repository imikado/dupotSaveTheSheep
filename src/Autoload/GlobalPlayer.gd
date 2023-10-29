extends Node

const START_SCORE = 0
const START_LIFE = 100
const START_MANA = 10
const MAX_MANA = 80

var _score = 0
var life = START_LIFE
var mana = START_MANA
var _level = 1

var attack_amount_mana = 10


func set_level(level):
	_level = level


func get_level():
	return _level


func reset_game():
	_level = 1
	_score = START_SCORE
	life = START_LIFE
	mana = START_MANA


func get_score():
	return _score


func save_score(score):
	_score = score


func increment_mana(value):
	mana += value
	if mana > MAX_MANA:
		mana = MAX_MANA


func use_amount_mana(value):
	mana -= value


func can_use_amount_mana(value):
	if mana >= value:
		return true
	return false


func decrease_health(value):
	life -= value


func update_life(value):
	life = value
