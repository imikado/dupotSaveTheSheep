extends Control

@onready var lifeSprite = $Sprite2D

@onready var lifesNode = $lifes
var life_icons: Array[Sprite2D] = []

var lifes: int = 3

func _ready() -> void:
	lifeSprite.visible = false
	for i in range(lifes):
		var newLife := lifeSprite.duplicate()

		lifesNode.add_child(newLife)
		life_icons.append(newLife)

		newLife.position.x += (i * 20)
		newLife.visible = true

func decrease_life():
	if lifes > 0:
		lifes -= 1
		life_icons[lifes].modulate.a = 0.3
	
	if lifes == 0:
		GlobalEvents.bonus_animation_gameover.emit();
