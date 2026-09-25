extends SceneTree

## Headless checks for save, reload, v1 migration, and offline earnings.
## Run: godot --headless --path mobile/ChopperMobile --script res://tests/save_checks.gd

func _initialize() -> void:
	var gs := root.get_node_or_null("GameState")
	if gs == null:
		_fail("GameState autoload missing")
		return
	gs.chopper.auto_chop_rate = 2.0
	gs.chops = 10
	gs._save_game()

	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(gs.SAVE_PATH))
	if int(saved.get("version", -1)) != 2:
		_fail("save version is %s" % saved.get("version"))
		return
	if int(saved.get("saved_unix", 0)) <= 0:
		_fail("saved_unix missing")
		return

	saved["version"] = 1
	saved.erase("saved_unix")
	saved.erase("effective_auto_chop_rate")
	saved["chops"] = 42
	_write(gs.SAVE_PATH, saved)
	if not gs._load_game():
		_fail("v1 save did not load")
		return
	if gs.chops != 42 or gs.offline_earnings != 0:
		_fail("v1 migrated as chops=%s offline=%s" % [gs.chops, gs.offline_earnings])
		return

	var now := int(Time.get_unix_time_from_system())
	saved = JSON.parse_string(FileAccess.get_file_as_string(gs.SAVE_PATH))
	saved["version"] = 2
	saved["saved_unix"] = now - 100
	saved["effective_auto_chop_rate"] = 2.0
	saved["chops"] = 10
	_write(gs.SAVE_PATH, saved)
	if not gs._load_game():
		_fail("offline save did not load")
		return
	if gs.offline_earnings != 200 or gs.chops != 210:
		_fail("offline earnings=%s chops=%s" % [gs.offline_earnings, gs.chops])
		return

	saved = JSON.parse_string(FileAccess.get_file_as_string(gs.SAVE_PATH))
	saved["saved_unix"] = now + 5000
	saved["effective_auto_chop_rate"] = 5.0
	saved["chops"] = 7
	_write(gs.SAVE_PATH, saved)
	if not gs._load_game():
		_fail("backwards-clock save did not load")
		return
	if gs.offline_earnings != 0 or gs.chops != 7:
		_fail("backwards clock earned=%s chops=%s" % [gs.offline_earnings, gs.chops])
		return

	saved = JSON.parse_string(FileAccess.get_file_as_string(gs.SAVE_PATH))
	saved["saved_unix"] = now - (UpgradeConfig.OFFLINE_EARNINGS_CAP_SECONDS + 10000)
	saved["effective_auto_chop_rate"] = 1.0
	saved["chops"] = 1
	_write(gs.SAVE_PATH, saved)
	if not gs._load_game():
		_fail("capped save did not load")
		return
	if gs.offline_earnings != UpgradeConfig.OFFLINE_EARNINGS_CAP_SECONDS:
		_fail("cap earned=%s" % gs.offline_earnings)
		return

	gs.chops = 99
	gs.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	saved = JSON.parse_string(FileAccess.get_file_as_string(gs.SAVE_PATH))
	if int(saved.get("chops", -1)) != 99:
		_fail("pause notification did not save chops")
		return

	print("SAVE_CHECKS_OK")
	quit(0)


func _write(path: String, data: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))


func _fail(message: String) -> void:
	print("SAVE_CHECKS_FAIL ", message)
	quit(1)
