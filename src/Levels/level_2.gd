extends LevelBase


func _ready() -> void:
	GlobalGame.saveLevel(2)

	super._ready()

	GlobalEvents.get_key.connect(on_get_key)

	GlobalGame.saveLevelPlayerLife(GlobalPlayer.get_life())
	GlobalGame.saveLevelSheepLife(GlobalSheep.get_life())
	GlobalGame.saveLevelWaterValue(GlobalPlayer.get_water())
	GlobalGame.saveLevelScore(GlobalPlayer.get_score())

	hud.disableProgression()


func on_get_key():
	hud.enable_key()


func on_end_level():
	if _level_ended:
		return
	GlobalPlayer.increase_score(100)
	super.on_end_level()
