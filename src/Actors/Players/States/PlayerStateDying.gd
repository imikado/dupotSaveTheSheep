extends  PlayerState

# Looping pain animation, Player.gd drives the death hop then emits the game over
func on_animation_finished(_anim_name:String):
	animation_play(animation_name)
