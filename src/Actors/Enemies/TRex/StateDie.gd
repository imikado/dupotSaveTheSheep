extends EnemyState


func on_animation_finished(anim_name:String):
	get_actor().finish_die()
