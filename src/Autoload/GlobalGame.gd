extends Node

const DEBUG_ENABLED = false

const GROUP_ENEMY := "enemy"
const GROUP_BONUSACTOR := "bonusactor"

const PATH_HIGHSCORE := "user://highscore.dat"
const MAX_HIGHSCORES := 10

enum ENEMY_TYPE_LIST {ANT, SPIDER, BEETLE}

enum LEVEL_DIFFICULTY {EASY, NORMAL}

var _is_debug := false

var _is_controls_enabled := false

var _last_screenshot

enum CAMERA_MODE_LIST {ZOOMED_CAMERA, PLAYER_CAMERA}

var camera_mode = CAMERA_MODE_LIST.PLAYER_CAMERA

const LEVEL_EASY_START_WATER = 50
const LEVEL_NORMAL_START_WATER = 20

const LEVEL_EASY_COEF_WATER = 2
const LEVEL_NORMAL_COEF_WATER = 1

const LEVEL_EASY_PLAYER_START_LIFE = 100
const LEVEL_NORMAL_PLAYER_START_LIFE = 90

const LEVEL_EASY_SHEEP_START_LIFE = 50
const LEVEL_NORMAL_SHEEP_START_LIFE = 20

var player_start_water = LEVEL_NORMAL_START_WATER
var player_coef_water = LEVEL_NORMAL_COEF_WATER
var player_start_life = LEVEL_NORMAL_PLAYER_START_LIFE
var sheep_start_life = LEVEL_NORMAL_SHEEP_START_LIFE

var _level_difficulty = LEVEL_DIFFICULTY.NORMAL

var levelPlayerLife=0
var levelSheepLife=0
var levelWaterValue=0
var levelScore=0

var currentLevel=0

# Identifies the current game in the high scores
var _run_id := ""

func saveLevel(newLevel):
	currentLevel=newLevel
	
func getLevel():
	return currentLevel

func saveLevelPlayerLife(levelValue):
	levelPlayerLife=levelValue

func saveLevelSheepLife(levelValue):
	levelSheepLife=levelValue

func saveLevelWaterValue(levelValue):
	levelWaterValue=levelValue

func saveLevelScore(levelValue):
	levelScore=levelValue

func getLevelPlayerLife():
	return levelPlayerLife
	
func getLevelSheepLife():
	return levelSheepLife
	
func getLevelWaterValue():
	return levelWaterValue
	
func getLevelScore():
	return levelScore

func isLevelDifficultyEasy():
	return _level_difficulty == LEVEL_DIFFICULTY.EASY

func isLevelDifficultyNormal():
	return _level_difficulty == LEVEL_DIFFICULTY.NORMAL

func getLevelDifficulty() -> LEVEL_DIFFICULTY:
	return _level_difficulty


func loadDifficulty(levelDifficulty: LEVEL_DIFFICULTY):
	_level_difficulty = levelDifficulty
	if levelDifficulty == LEVEL_DIFFICULTY.EASY:
		player_start_water = LEVEL_EASY_START_WATER
		player_coef_water = LEVEL_EASY_COEF_WATER
		player_start_life = LEVEL_EASY_PLAYER_START_LIFE
		sheep_start_life = LEVEL_EASY_SHEEP_START_LIFE
	elif levelDifficulty == LEVEL_DIFFICULTY.NORMAL:
		player_start_water = LEVEL_NORMAL_START_WATER
		player_coef_water = LEVEL_NORMAL_COEF_WATER
		player_start_life = LEVEL_NORMAL_PLAYER_START_LIFE
		sheep_start_life = LEVEL_NORMAL_SHEEP_START_LIFE

func isPlayerCameraMode():
	if camera_mode == CAMERA_MODE_LIST.PLAYER_CAMERA:
		return true
	return false

func isZoomedCameraMode():
	if camera_mode == CAMERA_MODE_LIST.ZOOMED_CAMERA:
		return true
	return false


func resetGame():
	# Otherwise game over still offers to replay level 2 from a previous game
	currentLevel = 0
	_run_id = str(Time.get_unix_time_from_system())
	GlobalPlayer.reset_game()
	GlobalSheep.reset_game()


func isControlsEnabled():
	return _is_controls_enabled


func setControlsEnabled(enabled):
	_is_controls_enabled = enabled


func is_debug():
	return _is_debug


func saveHighScore(newScoreValue):
	var dt := Time.get_datetime_dict_from_system()
	var dateTimeString := "%04d-%02d-%02d %02d:%02d:%02d" % [
		dt.year, dt.month, dt.day,
		dt.hour, dt.minute, dt.second
	]

	var highScoreList = getHighScoreList()

	if newScoreValue <= 0:
		return

	# One line per game: a replay of level 2 updates the line of its game
	for scoreLoop in highScoreList.duplicate():
		if _run_id != "" and scoreLoop.get("run", "") == _run_id:
			newScoreValue = max(newScoreValue, scoreLoop.score)
			highScoreList.erase(scoreLoop)

	var newScoreObj = {"score": newScoreValue, "date": dateTimeString, "run": _run_id}

	highScoreList.append(newScoreObj)
	highScoreList.sort_custom(func(a, b): return a.score > b.score)
	highScoreList = highScoreList.slice(0, MAX_HIGHSCORES)

	var jsonList = JSON.stringify(highScoreList)
	saveFile(PATH_HIGHSCORE, jsonList)


func getHighestScore(highScoreList):
	var highestScore = 0
	for highScoreLoop in highScoreList:
		if highScoreLoop.score > highestScore:
			highestScore = highScoreLoop.score

	return highestScore


func getHighScoreList() -> Array:
	if not FileAccess.file_exists(PATH_HIGHSCORE):
		return []

	var content := load_file(PATH_HIGHSCORE)

	var parsed = JSON.parse_string(content)
	if parsed is Array:
		return parsed

	return []


func saveFile(filepath: String, content: String) -> void:
	var file := FileAccess.open(filepath, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(content)


func load_file(filepath: String) -> String:
	var file := FileAccess.open(filepath, FileAccess.READ)
	if file == null:
		return ""
	return file.get_as_text()
	
func set_last_screenshot(screenshot: Texture) -> void:
	_last_screenshot = screenshot

func get_last_screenshot() -> Texture:
	return _last_screenshot
