extends SceneTree
## Build-time content check. Exit code 1 on any bad entry.
## Run: godot --headless --path . -s res://tools/validate_content.gd

const Loader = preload("res://src/content/content_loader.gd")


func _init() -> void:
	var r := Loader.load_all()
	if r.ok:
		print("content OK: %d units, %d items, %d placement questions, %d tips" % [
			r.units.size(), r.items.size(), r.placement.size(), r.tips.size()])
		quit(0)
	else:
		for e in r.errors:
			printerr("CONTENT ERROR: " + e)
		printerr("%d content error(s)" % r.errors.size())
		quit(1)
