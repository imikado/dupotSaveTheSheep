extends CanvasLayer

@onready var animationPlayer : AnimationPlayer =  $AnimationPlayer

var _is_transitioning := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func change_scene_to_packed(target:PackedScene)->void:
	if _is_transitioning:
		return
	_is_transitioning = true
	animationPlayer.play('dissolve')
	await animationPlayer.animation_finished
	get_tree().change_scene_to_packed(target)
	animationPlayer.play_backwards("dissolve")
	_is_transitioning = false
