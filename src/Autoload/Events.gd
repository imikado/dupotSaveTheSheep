extends Node

signal player_health_changed(new_value)

signal actor_took_damage(actor, damage)

signal actor_took_damage_by_bullet(actor, damage, bullet)

signal actor_let_item(actor)

signal actor_health_changed(actor, previous_value, new_value)

signal player_launch_mana_attack

signal player_took_lifebottle(bottle)

signal player_tookadvantage_of_lifebottle

signal player_gameover
