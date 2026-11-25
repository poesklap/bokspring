extends Node
## Screen manager: start menu, placement test, settings, and the game skin.
## Menus are plain Godot Controls built in code (see src/ui/).

const Menu = preload("res://src/ui/start_menu.gd")
const PlacementScreen = preload("res://src/ui/placement_screen.gd")
const SettingsScreen = preload("res://src/ui/settings_screen.gd")
const BokspringSkin = preload("res://src/skins/bokspring/bokspring_skin.gd")

var ui_layer: CanvasLayer
var screen: Control
var skin: SkinBase
var theme: Theme
var _pending_notice := ""


func _ready() -> void:
	theme = Style.make_theme()
	RenderingServer.set_default_clear_color(Style.BG)
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 5
	add_child(ui_layer)
	Game.voice_notice.connect(_on_voice_notice)
	if not Game.content_ok:
		_show_error()
		return
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shot=") and not OS.has_feature("web"):
			var shot: Node = load("res://src/dev/shot.gd").new()
			add_child(shot)
			shot.run(self, a.trim_prefix("--shot="))
			return
	if not bool(Game.engine.progress.placementDone):
		show_placement(true)
	else:
		show_menu()


func _clear() -> void:
	if screen:
		screen.queue_free()
		screen = null
	if skin:
		skin.queue_free()
		skin = null


func _mount(c: Control) -> void:
	c.theme = theme
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(c)
	screen = c


func show_menu() -> void:
	_clear()
	Game.refresh_day()
	Game.play_music("menu_loop")
	var m := Menu.new()
	m.play.connect(start_game)
	m.open_settings.connect(show_settings)
	_mount(m)
	if _pending_notice != "":
		_notice_panel(_pending_notice)
		_pending_notice = ""


func show_placement(first_time: bool) -> void:
	_clear()
	Game.play_music("menu_loop")
	var p := PlacementScreen.new()
	p.first_time = first_time
	p.finished.connect(func(_level): show_menu())
	_mount(p)


func show_settings() -> void:
	_clear()
	var s := SettingsScreen.new()
	s.back.connect(show_menu)
	s.retake_placement.connect(func(): show_placement(false))
	_mount(s)


func start_game() -> void:
	_clear()
	skin = BokspringSkin.new()
	add_child(skin)
	skin.go_menu.connect(show_menu)
	skin.start(Game.engine, Game)


func _on_voice_notice(message: String) -> void:
	# Shown once, on the menu, never on top of a running level.
	if screen is Menu:
		_notice_panel(message)
	else:
		_pending_notice = message


func _notice_panel(message: String) -> void:
	var dim := ColorRect.new()
	dim.color = Style.SHADE
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(460, 0)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)
	var l := Label.new()
	l.text = message
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(420, 0)
	box.add_child(l)
	var ok := Button.new()
	ok.text = "OK"
	ok.pressed.connect(dim.queue_free)
	box.add_child(ok)


func _show_error() -> void:
	var l := Label.new()
	l.text = "Content failed to load:\n" + "\n".join(Game.content.errors.slice(0, 8))
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var c := MarginContainer.new()
	c.add_child(l)
	_mount(c)
