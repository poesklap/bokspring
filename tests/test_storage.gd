extends RefCounted
const Storage = preload("res://src/storage/storage.gd")
var t


func test_save_and_load_round_trip() -> void:
	var path := "user://test_roundtrip.json"
	t.ok(Storage.save_json(path, {"a": 1, "b": {"c": "môre"}}), "saved")
	var d := Storage.load_json(path)
	t.eq(int(d.a), 1, "number")
	t.eq(d.b.c, "môre", "unicode survives")
	DirAccess.open("user://").remove("test_roundtrip.json")


func test_missing_file_is_empty() -> void:
	t.eq(Storage.load_json("user://nope_nope.json"), {}, "empty")


func test_backup_round_trip_and_rejects_junk() -> void:
	var text := Storage.make_backup({"xp": 99}, {"bokspring": {"level": 3}}, {"music": 0.5})
	var r := Storage.parse_backup(text)
	t.ok(r.ok, "parsed")
	t.eq(int(r.progress.xp), 99, "xp")
	t.eq(int(r.skins.bokspring.level), 3, "skin state")
	t.ok(not Storage.parse_backup("{\"hello\": 1}").ok, "rejects other json")
	t.ok(not Storage.parse_backup("not json").ok, "rejects junk")
