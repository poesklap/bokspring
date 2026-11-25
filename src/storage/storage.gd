extends RefCounted
## Save/load JSON in user:// (IndexedDB on the web, persisted when an
## installed PWA). Learner progress, skin state and settings are separate
## files, so future skins can reuse progress.

const PROGRESS := "user://progress.json"
const SETTINGS := "user://settings.json"
const EXPORT_FORMAT := "bokspring-backup"


static func skin_path(skin_id: String) -> String:
	return "user://skin_%s.json" % skin_id


static func load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	return data if data is Dictionary else {}


static func save_json(path: String, data: Dictionary) -> bool:
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_warning("save failed: %s (%d)" % [path, FileAccess.get_open_error()])
		return false
	f.store_string(JSON.stringify(data))
	f.close()
	# Write-then-rename so a crash mid-save never leaves a half file.
	var d := DirAccess.open("user://")
	if FileAccess.file_exists(path):
		d.remove(path.get_file())
	return d.rename(tmp.get_file(), path.get_file()) == OK


## One JSON blob with everything, for the export/import backup.
static func make_backup(progress: Dictionary, skins: Dictionary, settings: Dictionary) -> String:
	return JSON.stringify({
		"format": EXPORT_FORMAT, "version": 1,
		"exportedAt": Time.get_datetime_string_from_system(),
		"progress": progress, "skins": skins, "settings": settings,
	}, "  ")


## Returns {ok, error, progress, skins, settings}.
static func parse_backup(text: String) -> Dictionary:
	var data = JSON.parse_string(text)
	if not data is Dictionary or data.get("format") != EXPORT_FORMAT:
		return {"ok": false, "error": "This isn't a Bokspring backup file."}
	if not data.get("progress") is Dictionary:
		return {"ok": false, "error": "The backup has no progress in it."}
	return {"ok": true, "error": "", "progress": data.progress,
		"skins": data.get("skins", {}) if data.get("skins") is Dictionary else {},
		"settings": data.get("settings", {}) if data.get("settings") is Dictionary else {}}


static func wipe_all() -> void:
	var d := DirAccess.open("user://")
	if d == null:
		return
	for f in d.get_files():
		if f.ends_with(".json") or f.ends_with(".tmp"):
			d.remove(f)
