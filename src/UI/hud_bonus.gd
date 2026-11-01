extends Control

# Lives of the motorbike bonus level, shown as small bikes in their own HUD panel

const LIFE_TEXTURE := preload("res://src/UI/Controls/Shared/icon-motorbike.png")
const LOST_TEXTURE := preload("res://src/UI/Controls/Shared/icon-motorbike-lost.png")
# Blinks of the bike that was just lost
const LOST_BLINKS := 3
const LOST_BLINK_TIME := 0.08

@onready var life_icons: Array[Node] = $lifes.get_children()

var lifes: int = 3

func decrease_life():
	if lifes > 0:
		lifes -= 1
		_blink_lost(life_icons[lifes])

	if lifes == 0:
		GlobalEvents.bonus_animation_gameover.emit();

# Pixel-clean feedback: the icon flips between full and lost a few times
func _blink_lost(icon: TextureRect):
	var tween := create_tween()
	for i in LOST_BLINKS:
		tween.tween_callback(func(): icon.texture = LOST_TEXTURE)
		tween.tween_interval(LOST_BLINK_TIME)
		tween.tween_callback(func(): icon.texture = LIFE_TEXTURE)
		tween.tween_interval(LOST_BLINK_TIME)
	tween.tween_callback(func(): icon.texture = LOST_TEXTURE)
