extends SceneTree
# Pilote automatique utilisé pour enregistrer le GIF de promotion et les
# screenshots (voir tools/capture/capture.sh).
#
# Lancé par Godot en mode Movie Maker (--write-movie) : le temps est fixe,
# chaque image est enregistrée, la partie est donc reproductible.

# Storyboard (secondes) : menu, niveau 1, niveau bonus, puis mode 2 joueurs
# (menu, écran des touches à deux, niveau 1 à deux, bonus à deux motos), fin
const LEVEL_START = 2.5
const BONUS_START = 34.0
const COOP_MENU_START = 50.0
# Durée du menu avec le focus sur 2 PLAYERS, puis de l'écran des touches
const COOP_MENU_TIME = 1.0
const COOP_CONTROLS_TIME = 2.5
const COOP_BONUS_START = 72.0
const COOP_BANNER_TIME = 3.0
const END = 82.0

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
# Mode 2 joueurs : le joueur 2 suit le joueur 1 à cette distance
const FOLLOW_DISTANCE = 22.0
const FOLLOW_DEAD_ZONE = 4.0
# Position dans la zone d'action d'une grille ou d'une poignée
const JOIN_DISTANCE = 17.0
# Durée pendant laquelle une action lancée par le joueur 1 reste en cours
const ACTION_PENDING_TIME = 1.0

var _time := 0.0
var _step := 0
# Délais par joueur (1 ou 2)
var _shoot_cooldown := {1: 0.0, 2: 0.0}
var _action_cooldown := {1: 0.0, 2: 0.0}
var _jump_cooldown := {1: 0.0, 2: 0.0}
var _actions_done := {}
var _banner: CanvasLayer = null
var _banner_shown := false
var _coop_focus_time := 0.0

# Les autoloads ne sont pas visibles à la compilation d'un script lancé par -s
var GlobalPlayer
var GlobalSheep
var GlobalInput
var GlobalTransition
var GlobalGame

func _initialize():
	GlobalGame = root.get_node("GlobalGame")
	GlobalPlayer = root.get_node("GlobalPlayer")
	GlobalSheep = root.get_node("GlobalSheep")
	GlobalInput = root.get_node("GlobalInput")
	GlobalTransition = root.get_node("GlobalTransition")
	# Keyboard look (keys help, no touch buttons) even on a touchscreen PC.
	# Deferred: GlobalInput detects the touchscreen in its _ready, after this
	GlobalInput.set_touch_mode.call_deferred(false)
	# Deferred: after the _ready of GlobalInput (it loads the saved controls)
	_default_controls.call_deferred()
	change_scene_to_file("res://src/UI/Screens/Menu.tscn")

# Default controls, all on the keyboard, without touching the saved ones
func _default_controls():
	GlobalInput.save_enabled = false
	GlobalInput.reset_profiles()
	for profile in GlobalInput.PROFILES:
		GlobalInput.profiles[profile]["device"] = GlobalInput.Device.KEYBOARD
	GlobalInput.apply()

func _process(delta):
	_time += delta

	if _step == 0 and _time >= LEVEL_START:
		_step = 1
		current_scene.start_game(false)
	elif _step == 1 and _time >= BONUS_START:
		_step = 2
		GlobalInput.reset_move()
		GlobalTransition.change_scene_to_packed(load("res://src/Levels/bonus_level_1.tscn"))
	elif _step == 2 and _time >= COOP_MENU_START:
		_step = 3
		_release_input_name(GlobalInput.INPUT_JUMP)
		GlobalTransition.change_scene_to_packed(load("res://src/UI/Screens/Menu.tscn"))
	elif _step == 3 and current_scene != null and current_scene.get_node_or_null("%TwoPlayersButton") != null:
		_step = 4
		_coop_focus_time = _time
		current_scene.get_node("%TwoPlayersButton").grab_focus()
	elif _step == 4 and _time >= _coop_focus_time + COOP_MENU_TIME:
		# Écran des touches des deux joueurs
		_step = 6
		current_scene._on_two_players_button_pressed()
	elif _step == 6 and _time >= _coop_focus_time + COOP_MENU_TIME + COOP_CONTROLS_TIME:
		_step = 5
		current_scene.start_game(true)
	elif _step == 5 and _time >= COOP_BONUS_START:
		# Bonus à deux motos
		_step = 7
		GlobalInput.reset_move()
		GlobalInput.reset_move(2)
		GlobalTransition.change_scene_to_packed(load("res://src/Levels/bonus_level_1.tscn"))
	elif _time >= END:
		quit()
		return false

	if _step == 1 or _step == 5:
		var actors = GlobalPlayer.get_actors()
		if actors.size() >= 1:
			_drive(actors[0], delta)
		if actors.size() >= 2:
			_show_coop_banner()
			_drive_follower(actors[1], actors[0], delta)
	elif _step == 2 or _step == 7:
		_drive_bike(delta)
	_update_banner()
	return false

# Bandeau « 2 PLAYERS MODE » au début du niveau à deux
func _show_coop_banner():
	if _banner_shown:
		return
	_banner_shown = true
	_banner = CanvasLayer.new()
	_banner.layer = 50
	_banner.set_meta("start", _time)
	var label = Label.new()
	label.text = "2 PLAYERS MODE"
	label.add_theme_font_override("font", load("res://src/UI/Controls/Shared/Pixeled.ttf"))
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(0, 54)
	label.size = Vector2(480, 30)
	_banner.add_child(label)
	current_scene.add_child(_banner)

func _update_banner():
	if _banner == null or !is_instance_valid(_banner):
		return
	var age = _time - _banner.get_meta("start")
	if age > COOP_BANNER_TIME:
		_banner.queue_free()
		_banner = null
	elif age > COOP_BANNER_TIME - 0.5:
		_banner.get_child(0).modulate.a = (COOP_BANNER_TIME - age) / 0.5

# Niveau bonus : sauter les obstacles
# Niveau bonus : sauter les obstacles (à deux : chaque moto sur sa route)
func _drive_bike(delta: float):
	for index in [1, 2]:
		_jump_cooldown[index] = max(_jump_cooldown[index] - delta, 0.0)
		GlobalPlayer.update_life(max(GlobalPlayer.get_life(index), 50), index)
	var main_bike = current_scene.get("_player")
	if main_bike == null or !is_instance_valid(main_bike) or !main_bike.is_inside_tree():
		return
	for obstacle in current_scene.get_children():
		var script = obstacle.get_script()
		if script == null or !script.resource_path.ends_with("BonusObstacle.gd"):
			continue
		var bike = obstacle.get_meta("bike", main_bike)
		var index = bike.player_index
		var dx = obstacle.global_position.x - bike.global_position.x
		if dx > 0 and dx < BIKE_JUMP_DISTANCE and _jump_cooldown[index] == 0.0:
			_tap(_input_name(GlobalInput.INPUT_JUMP, index))
			_jump_cooldown[index] = 0.5

func _update_cooldowns(index: int, delta: float):
	_shoot_cooldown[index] = max(_shoot_cooldown[index] - delta, 0.0)
	_action_cooldown[index] = max(_action_cooldown[index] - delta, 0.0)
	_jump_cooldown[index] = max(_jump_cooldown[index] - delta, 0.0)

func _avoid_sheep(player, sheep):
	# Le mouton fait demi-tour s'il bute sur Gordon : on évite ce blocage
	if sheep != null and !sheep.get_collision_exceptions().has(player):
		sheep.add_collision_exception_with(player)

# Nom de l'action d'entrée pour le joueur
func _input_name(action: String, index: int) -> String:
	return GlobalInput.get_action_name(action, index)

# Mode 2 joueurs : le joueur 2 suit le joueur 1, l'aide à tirer et le
# rejoint sur la grille ou la poignée qu'il est en train d'actionner
func _drive_follower(player, leader, delta: float):
	var sheep = _find_sheep()
	_avoid_sheep(player, sheep)
	_update_cooldowns(2, delta)
	var enemy = _nearest_enemy(player, sheep)
	var target = player._pending_action
	var waiting = leader._pending_action != null and _coop_waiting(leader._pending_action)
	if target != null and _coop_waiting(target):
		_release_move(2)
		if _action_cooldown[2] == 0.0 and player.get_current_state().name != "StateAction":
			player.action()
			_action_cooldown[2] = 2.0
	elif enemy != null and abs(enemy.global_position.x - player.global_position.x) < DANGER_RANGE and !waiting:
		_shoot_at(player, enemy, 2)
	else:
		# Rejoint la zone d'action de la grille ou de la poignée, côté droit
		# (à gauche, il resterait perché sur la grille)
		var goal = leader.global_position.x - FOLLOW_DISTANCE
		if waiting:
			goal = leader._pending_action.global_position.x + JOIN_DISTANCE
		var dx = goal - player.global_position.x
		GlobalInput.reset_move(2)
		if abs(dx) > FOLLOW_DEAD_ZONE:
			Input.action_press(_input_name(GlobalInput.INPUT_RIGHT if dx > 0 else GlobalInput.INPUT_LEFT, 2))
			# Obstacle, ou joueur 1 plus haut : sauter
			var blocked = player.is_on_wall() or leader.global_position.y < player.global_position.y - 20
			if blocked and _jump_cooldown[2] == 0.0:
				_tap(_input_name(GlobalInput.INPUT_JUMP, 2))
				_jump_cooldown[2] = 0.6

func _coop_waiting(target) -> bool:
	return is_instance_valid(target) and target.get_node_or_null("CoopAction") != null

func _drive(player, delta: float):
	var sheep = _find_sheep()
	_avoid_sheep(player, sheep)

	# Pas de game over pendant l'enregistrement
	GlobalPlayer.update_life(max(GlobalPlayer.get_life(), 50))
	GlobalPlayer.update_life(max(GlobalPlayer.get_life(2), 50), 2)
	GlobalSheep.update_life(max(GlobalSheep.get_life(), 50))
	if GlobalPlayer.get_water() < 10:
		GlobalPlayer.increment_water(10 - GlobalPlayer.get_water())

	_update_cooldowns(1, delta)
	var enemy = _nearest_enemy(player, sheep)
	var target = player._pending_action
	if enemy != null and abs(enemy.global_position.x - player.global_position.x) < DANGER_RANGE:
		# Ennemi trop proche : il interromprait toute action
		_shoot_at(player, enemy)
	elif target != null and _needs_action(target):
		_release_move()
		# Appel direct : l'appui sur « action » n'est lu que dans certains états
		if _action_cooldown[1] == 0.0 and player.get_current_state().name != "StateAction":
			player.action()
			_action_cooldown[1] = 2.0
	elif player.is_on_wall() and Input.is_action_pressed(_input_name(GlobalInput.INPUT_RIGHT, 1)):
		# Obstacle (grille...) : on saute par-dessus en gardant la direction
		if _jump_cooldown[1] == 0.0:
			_tap(_input_name(GlobalInput.INPUT_JUMP, 1))
			_jump_cooldown[1] = 0.6
	elif _next_closed_gate(player, sheep) != null:
		# Grille fermée devant le mouton : y aller (saut par-dessus) et l'ouvrir
		var gate = _next_closed_gate(player, sheep)
		GlobalInput.reset_move()
		if player.global_position.x > gate.global_position.x + 12:
			Input.action_press(_input_name(GlobalInput.INPUT_LEFT, 1))
		else:
			Input.action_press(_input_name(GlobalInput.INPUT_RIGHT, 1))
	elif enemy != null:
		_shoot_at(player, enemy)
	elif sheep != null:
		var lead = player.global_position.x - sheep.global_position.x
		if lead < LEAD_MIN:
			Input.action_press(_input_name(GlobalInput.INPUT_RIGHT, 1))
		elif lead > LEAD_MAX:
			_release_move()
	else:
		Input.action_press(_input_name(GlobalInput.INPUT_RIGHT, 1))

# Grille : à ouvrir. Autres mécanismes (pont, ascenseur) : une seule fois,
# en attendant le joueur 2 en mode 2 joueurs.
func _needs_action(target) -> bool:
	if "_is_open" in target:
		return !target._is_open
	if _coop_waiting(target):
		return true
	if _actions_done.has(target):
		return GlobalGame.is_two_players() and _time - _actions_done[target] < ACTION_PENDING_TIME
	_actions_done[target] = _time
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
func _shoot_at(player, enemy, index := 1):
	_release_move(index)
	var enemy_on_left = enemy.global_position.x < player.global_position.x
	if enemy_on_left != player._sprite.flip_h:
		_tap(_input_name(GlobalInput.INPUT_LEFT if enemy_on_left else GlobalInput.INPUT_RIGHT, index))
	elif _shoot_cooldown[index] == 0.0:
		_tap(_input_name(GlobalInput.INPUT_ATTACK, index))
		_shoot_cooldown[index] = 0.35

func _release_move(index := 1):
	GlobalInput.reset_move(index)

func _release_input_name(action: String):
	Input.action_release(action)

func _tap(action: String):
	Input.action_press(action)
	await process_frame
	await process_frame
	Input.action_release(action)
