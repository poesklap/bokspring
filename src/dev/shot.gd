extends Node
## Dev only: `godot --path . -- --shot=/abs/dir` drives the app through its
## screens and saves screenshots, then quits. Not reachable in the web build.

var main: Node
var dir := ""


func run(p_main: Node, p_dir: String) -> void:
	main = p_main
	dir = p_dir
	DirAccess.make_dir_recursive_absolute(dir)
	Game.engine.progress.placementDone = true
	await _wait(1.0)
	main.show_menu()
	await _wait(0.8)
	await _snap("01_menu")
	main.show_placement(false)
	await _wait(0.5)
	await _snap("02_placement")
	main.show_settings()
	await _wait(0.5)
	await _snap("03_settings")
	main.start_game()
	await _wait(2.4)
	await _snap("04_run_prompt")
	var skin = main.skin
	skin._select(int(skin.challenge.correctIndex))
	await _wait(0.35)
	await _snap("05_run_obstacles")
	await _wait(1.6)
	await _snap("06_next_prompt")
	var wrong := (int(skin.challenge.correctIndex) + 1) % int(skin.lanes)
	skin._select(wrong)
	await _wait(1.0)
	await _snap("07_crash_pair")
	await _wait(2.0)
	await _snap("08_after_crash")
	skin.challenge = {}
	await time_restart(main)
	get_tree().quit()


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _snap(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(dir.path_join(name + ".png"))
	print("shot ", name)


## Dev check: time from tapping "Weer!" to the first challenge being playable.
func time_restart(p_main: Node) -> void:
	var skin = p_main.skin
	var t0 := Time.get_ticks_msec()
	skin.start_level(true)
	while skin.challenge.is_empty() or skin.state != skin.S.RUN:
		await get_tree().process_frame
	print("restart_ms ", Time.get_ticks_msec() - t0)
