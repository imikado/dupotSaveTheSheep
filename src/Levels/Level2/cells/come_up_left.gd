extends Node2D

@onready var canon_rex :CanonRex = $CanonRex
 
func _on_start_enemy_shoot_body_entered(body:Node2D) -> void:
    if body is Player:
        canon_rex.enable()
    
