extends SceneTree
## Minimal headless test runner (no plugins needed).
## Run:  godot --headless --path . -s res://tests/run_tests.gd
## Every tests/test_*.gd file is loaded; each method named test_* is run with a
## fresh instance. Exit code 0 = all passed.

var failures: Array = []
var current := ""
var checks := 0


func _init() -> void:
	var files: Array = []
	var dir := DirAccess.open("res://tests")
	for f in dir.get_files():
		if f.begins_with("test_") and f.ends_with(".gd"):
			files.append(f)
	files.sort()
	var ran := 0
	for f in files:
		var script: GDScript = load("res://tests/" + f)
		if script == null or not script.can_instantiate():
			failures.append(f + ": failed to load (parse error)")
			continue
		for m in script.get_script_method_list():
			var name: String = m.name
			if not name.begins_with("test_"):
				continue
			var inst = script.new()
			inst.set("t", self)
			current = f + "::" + name
			inst.call(name)
			ran += 1
	print("\n%d tests, %d checks, %d failures" % [ran, checks, failures.size()])
	for f in failures:
		printerr("FAIL " + f)
	quit(0 if failures.is_empty() and ran > 0 else 1)


func ok(cond: bool, msg: String = "") -> void:
	checks += 1
	if not cond:
		failures.append("%s: %s" % [current, msg])


func eq(a, b, msg: String = "") -> void:
	checks += 1
	if typeof(a) != typeof(b) and not (a is float or a is int) and not (b is float or b is int):
		failures.append("%s: %s expected %s got %s" % [current, msg, str(b), str(a)])
	elif a != b:
		failures.append("%s: %s expected %s got %s" % [current, msg, str(b), str(a)])
