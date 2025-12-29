extends Node2D


enum EnemyType {TREX, OTHER}
@export var enemy_type: EnemyType

@onready var spawn_position: Marker2D = $spawnArea/spawnPosition

@onready var enemies:Node2D = $enemies


func _on_spawn_area_body_entered(body: Node2D) -> void:
	if (body is not Player):
		return

	var new_enemy: Enemy;

	if (enemy_type == EnemyType.TREX):
		new_enemy = TRex.create()
	else:
		return

	if enemies.get_child_count() > 0:
		return

 
	new_enemy.position = spawn_position.position

	enemies.add_child(new_enemy)
