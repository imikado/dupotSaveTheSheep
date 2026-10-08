extends CharacterBody2D
class_name Enemy

var _alive=true


@export var points:int=0

func get_points():
	return points

# Visual feedback when hit by water
func hit_feedback():
	Fx.flash(self)

# Visual feedback when the enemy disappears
func die_feedback():
	var world = get_parent()
	Fx.smoke(world, global_position + Vector2(0, -16))
	if points > 0:
		Fx.popup_text(world, global_position + Vector2(0, -32), "+" + str(points), Fx.COLOR_HEAL)
