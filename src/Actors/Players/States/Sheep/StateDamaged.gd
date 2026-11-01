extends SheepState

func on_animation_finished(_anim_name:String):
	get_actor().end_damage()
