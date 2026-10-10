extends SceneTree
# Pilote automatique utilisé pour enregistrer le GIF de promotion et les
# screenshots (voir tools/capture/capture.sh).
#
# Lancé par Godot en mode Movie Maker (--write-movie) : le temps est fixe,
# chaque image est enregistrée, la partie est donc reproductible.

# Storyboard (secondes) : menu, niveau 1, niveau bonus, fin
const LEVEL_START = 2.5
const BONUS_START = 34.0
const END = 50.0

# Distance que Gordon garde devant le mouton
const LEAD_MIN = 50.0
const LEAD_MAX = 110.0
# Distance de tir sur un ennemi devant Gordon
const SHOOT_RANGE = 170.0
const DANGER_RANGE = 110.0
# Distance mouton/grille fermée à partir de laquelle Gordon va l'ouvrir
const GATE_RANGE = 260.0
# Distance moto/obstacle à laquelle sauter
const BIKE_JUMP_DISTANCE = 100.0

var _time := 0.0
var _step := 0
var _shoot_cooldown := 0.0
var _actions_done := {}
var _action_cooldown := 0.0
var _jump_cooldown := 0.0

# Les autoloads ne sont pas visibles à la compilation d'un script lancé par -s
var GlobalPlayer
var GlobalSheep
var GlobalInput
var GlobalTransition

func _initialize():
	GlobalPlayer = root.get_node("GlobalPlayer")
	GlobalSheep = root.get_node("GlobalSheep")
	GlobalInput = root.get_node("GlobalInput")
	GlobalTransition = root.get_node("GlobalTransition")
	change_scene_to_file("res://src/UI/Screens/Menu.tscn")

func _process(delta):
	_time += delta

	if _step == 0 and _time >= LEVEL_START:
		_step = 1
		current_scene._on_play_button_pressed()
	elif _step == 1 and _time >= BONUS_START:
		_step = 2
		GlobalInput.reset_move()
		GlobalTransition.change_scene_to_packed(load("res://src/Levels/bonus_level_1.tscn"))
	elif _time >= END:
		quit()
		return false

	if _step == 1:
		var player = GlobalPlayer.get_actor()
		if is_instance_valid(player) and player.is_inside_tree():
			_drive(player, delta)
	elif _step == 2:
		_drive_bike(delta)
	return false

# Niveau bonus : sauter les obstacles
func _drive_bike(delta: float):
	_jump_cooldown = max(_jump_cooldown - delta, 0.0)
	GlobalPlayer.update_life(max(GlobalPlayer.get_life(), 50))
	var bike = current_scene.get("_player")
	if bike == null or !is_instance_valid(bike) or !bike.is_inside_tree():
		return
	for obstacle in current_scene.get_children():
		var script = obstacle.get_script()
		if script == null or !script.resource_path.ends_with("BonusObstacle.gd"):
			continue
		var dx = obstacle.global_position.x - bike.global_position.x
		if dx > 0 and dx < BIKE_JUMP_DISTANCE and _jump_cooldown == 0.0:
			_tap(GlobalInput.INPUT_JUMP)
			_jump_cooldown = 0.5

func _drive(player, delta: float):
	var sheep = _find_sheep()

	# Le mouton fait demi-tour s'il bute sur Gordon : on évite ce blocage
	if sheep != null and !sheep.get_collision_exceptions().has(player):
		sheep.add_collision_exception_with(player)

	# Pas de game over pendant l'enregistrement
	GlobalPlayer.update_life(max(GlobalPlayer.get_life(), 50))
	GlobalSheep.update_life(max(GlobalSheep.get_life(), 50))
	if GlobalPlayer.get_water() < 10:
		GlobalPlayer.increment_water(10 - GlobalPlayer.get_water())

	_shoot_cooldown = max(_shoot_cooldown - delta, 0.0)
	_action_cooldown = max(_action_cooldown - delta, 0.0)
	_jump_cooldown = max(_jump_cooldown - delta, 0.0)
	var enemy = _nearest_enemy(player, sheep)
	var target = player._pending_action
	if enemy != null and abs(enemy.global_position.x - player.global_position.x) < DANGER_RANGE:
		# Ennemi trop proche : il interromprait toute action
		_shoot_at(player, enemy)
	elif target != null and _needs_action(target):
		_release_move()
		# Appel direct : l'appui sur « action » n'est lu que dans certains états
		if _action_cooldown == 0.0 and player.get_current_state().name != "StateAction":
			player.action()
			_action_cooldown = 2.0
	elif player.is_on_wall() and Input.is_action_pressed(GlobalInput.INPUT_RIGHT):
		# Obstacle (grille...) : on saute par-dessus en gardant la direction
		if _jump_cooldown == 0.0:
			_tap(GlobalInput.INPUT_JUMP)
			_jump_cooldown = 0.6
	elif _next_closed_gate(player, sheep) != null:
		# Grille fermée devant le mouton : y aller (saut par-dessus) et l'ouvrir
		var gate = _next_closed_gate(player, sheep)
		GlobalInput.reset_move()
		if player.global_position.x > gate.global_position.x + 12:
			Input.action_press(GlobalInput.INPUT_LEFT)
		else:
			Input.action_press(GlobalInput.INPUT_RIGHT)
	elif enemy != null:
		_shoot_at(player, enemy)
	elif sheep != null:
		var lead = player.global_position.x - sheep.global_position.x
		if lead < LEAD_MIN:
			Input.action_press(GlobalInput.INPUT_RIGHT)
		elif lead > LEAD_MAX:
			_release_move()
	else:
		Input.action_press(GlobalInput.INPUT_RIGHT)

# Grille : à ouvrir. Autres mécanismes (pont, ascenseur) : une seule fois.
func _needs_action(target) -> bool:
	if "_is_open" in target:
		return !target._is_open
	if _actions_done.has(target):
		return false
	_actions_done[target] = true
	return true

func _next_closed_gate(player, sheep) -> Node2D:
	if sheep == null:
		return null
	for gate in current_scene.find_children("Gate", "", true, false):
		var dx = gate.global_position.x - sheep.global_position.x
		var passed = gate.global_position.x < player.global_position.x + 20
		if "_is_open" in gate and !gate._is_open and dx > 0 and (dx < GATE_RANGE or passed):
			return gate
	return null

func _find_sheep() -> Node2D:
	var list = get_nodes_in_group("capture_sheep")
	if list.is_empty():
		for node in current_scene.find_children("*", "Sheep", true, false):
			node.add_to_group("capture_sheep")
			return node
		return null
	return list[0]

# Ennemi le plus proche, devant Gordon ou entre lui et le mouton
func _nearest_enemy(player, sheep) -> Node2D:
	var best = null
	var best_distance = SHOOT_RANGE
	var min_x = player.global_position.x - SHOOT_RANGE
	if sheep != null:
		min_x = max(min_x, sheep.global_position.x - 10)
	for enemy in current_scene.find_children("*", "Enemy", true, false):
		if !enemy.is_visible_in_tree() or !enemy._alive:
			continue
		if enemy.global_position.x < min_x or abs(enemy.global_position.y - player.global_position.y) > 60:
			continue
		var distance = abs(enemy.global_position.x - player.global_position.x)
		if distance < best_distance:
			best = enemy
			best_distance = distance
	return best

# Se tourner vers l'ennemi puis tirer
func _shoot_at(player, enemy):
	_release_move()
	var enemy_on_left = enemy.global_position.x < player.global_position.x
	if enemy_on_left != player._sprite.flip_h:
		_tap(GlobalInput.INPUT_LEFT if enemy_on_left else GlobalInput.INPUT_RIGHT)
	elif _shoot_cooldown == 0.0:
		_tap(GlobalInput.INPUT_ATTACK)
		_shoot_cooldown = 0.35

func _release_move():
	GlobalInput.reset_move()

func _tap(action: String):
	Input.action_press(action)
	await process_frame
	await process_frame
	Input.action_release(action)
