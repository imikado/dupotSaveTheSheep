extends EnemyState

func enter():
	super.enter()
	GlobalAudio.play_sfx("roar", 0.05, -3.0, 0.8)

func on_animation_finished(_anim_name:String):
	exit(TRexStateMachine.STATE_WALKING)
