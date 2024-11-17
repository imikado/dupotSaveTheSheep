extends Node

const DEBUG_ENABLED = false

const GROUP_ENEMY := "enemy"
const GROUP_BONUSACTOR := "bonusactor"

const PATH_HIGHSCORE := "user://highscore.dat"

enum ENEMY_TYPE_LIST { ANT, SPIDER, BEETLE }

var _is_debug := false

var _is_controls_enabled := true

var _last_screenshot

enum CAMERA_MODE_LIST {  ZOOMED_CAMERA,PLAYER_CAMERA }

var camera_mode=CAMERA_MODE_LIST.PLAYER_CAMERA

func isPlayerCameraMode():
	if camera_mode == CAMERA_MODE_LIST.PLAYER_CAMERA:
		return true
	return false

func isZoomedCameraMode():
	if camera_mode == CAMERA_MODE_LIST.PLAYER_CAMERA:
		return true
	return false


func resetGame():
	GlobalPlayer.reset_game()
	GlobalSheep.reset_game()
	pass


func isControlsEnabled():
	return _is_controls_enabled


func setControlsEnabled(enabled):
	_is_controls_enabled = enabled


func is_debug():
	return _is_debug


func saveHighScore(newScoreValue):
	#var datetimeNow = OS.get_datetime()

	var dateTimeString = ""

	var highScoreList = getHighScoreList()

	if !isHighestScore(highScoreList, newScoreValue):
		return

	var newScoreObj = {"score": newScoreValue, "date": dateTimeString}

	highScoreList.append(newScoreObj)

	#var jsonList = JSON.print(highScoreList)
	#saveFile(PATH_HIGHSCORE, jsonList)

	pass


func getHighestScore(highScoreList):
	var highestScore = 0
	for highScoreLoop in highScoreList:
		if highScoreLoop.score > highestScore:
			highestScore = highScoreLoop.score

	return highestScore


func isHighestScore(highScoreList, askScore):
	var highestScore = getHighestScore(highScoreList)
	if askScore > highestScore:
		return true

	return false


func getHighScoreList():
	return []
	

func saveFile(filepath, content):
	print(filepath)
	print(content)
	pass

func loadFile(filepath):
	print(filepath)
	pass
	
func set_last_screenshot(screenshot:Texture)->void:
	_last_screenshot=screenshot

func get_last_screenshot()->Texture:
	return _last_screenshot
