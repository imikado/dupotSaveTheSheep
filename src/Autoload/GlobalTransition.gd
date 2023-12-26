extends CanvasLayer

@onready var animationPlayer : AnimationPlayer =  $AnimationPlayer

func change_scene_to_packed(target:PackedScene)->void:
	animationPlayer.play('dissolve')
	await animationPlayer.animation_finished
	get_tree().change_scene_to_packed(target)
	animationPlayer.play_backwards("dissolve")
