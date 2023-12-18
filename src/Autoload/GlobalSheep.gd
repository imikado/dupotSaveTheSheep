extends Node

const START_LIFE = 50

var _life = START_LIFE

func reset_game():
    _life = START_LIFE

func get_life():
    return _life


func decrease_life(value):
    _life -= value


func update_life(value):
    _life = value
    