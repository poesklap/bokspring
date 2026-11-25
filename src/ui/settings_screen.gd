extends Control
## Settings: difficulty, music/sound volume, speech on/off and speed,
## reduce motion, colour-blind lanes, export/import, retake placement,
## reset progress, and a voice check for testing speech on a phone.

const U = preload("res://src/ui/ui_util.gd")
const Difficulty = preload("res://src/engine/difficulty.gd")

signal back
signal retake_placement

var box: VBoxContainer
var status: Label


func _ready() -> void:
	box = U.page(self, true)
	var head := HBoxContainer.new()
	box.add_child(head)
	U.button(head, "← Terug", func(): back.emit(), "GhostButton")
	U.label(head, "  Instellings", "TitleLabel")

	U.label(box, "Difficulty", "MutedLabel")
	var diff := OptionButton.new()
	diff.custom_minimum_size = Vector2(0, 64)
	for i in Difficulty.LEVELS.size():
		diff.add_item(str(Difficulty.profile(Difficulty.LEVELS[i]).label), i)
	diff.selected = maxi(0, Difficulty.LEVELS.find(str(Game.engine.progress.difficulty)))
	diff.item_selected.connect(func(i):
		Game.engine.set_difficulty(Difficulty.LEVELS[i])
		Game.save())
	box.add_child(diff)
	U.label(box, "Sets speed, lanes, how alike the wrong answers are, and when English → Afrikaans starts. The game keeps adapting within it.", "MutedLabel")

	_slider("Music", "music")
	_slider("Sound effects", "sfx")

	var has_voice := Game.has_afrikaans_voice()
	var sp := _toggle("Speak Afrikaans", "speech")
	var rate := _slider("Speech speed", "speechRate", 0.5, 1.5)
	if not has_voice:
		sp.disabled = true
		rate.editable = false
		U.label(box, "No Afrikaans voice on this device, so speech is off. If your phone offers one, add it in Settings → Accessibility → Spoken Content → Voices, then reopen the app.", "MutedLabel")

	_toggle("Reduce motion", "reduceMotion")
	_toggle("Colour-blind friendly lanes", "colorBlind")
	U.label(box, "Daily reminder: coming in a later update.", "MutedLabel")

	U.label(box, "Your progress", "MutedLabel")
	U.button(box, "Export progress (backup file)", func(): _say(Game.export_progress()), "SecondaryButton")
	U.button(box, "Import progress", func():
		Game.import_progress(func(err: String):
			_say("Progress restored." if err == "" else err)), "SecondaryButton")
	U.button(box, "Retake placement test", func(): retake_placement.emit(), "SecondaryButton")
	U.button(box, "Voice check (for testing speech)", _voice_check, "GhostButton")
	var reset := U.button(box, "Reset all progress", _confirm_reset, "GhostButton")
	reset.add_theme_color_override("font_color", Style.BAD)
	status = U.label(box, "", "", true)


func _say(t: String) -> void:
	status.text = t


func _slider(text: String, key: String, lo := 0.0, hi := 1.0) -> HSlider:
	U.label(box, text, "MutedLabel")
	var s := HSlider.new()
	s.min_value = lo
	s.max_value = hi
	s.step = 0.05
	s.value = float(Game.settings[key])
	s.custom_minimum_size = Vector2(0, 64)
	s.value_changed.connect(func(v): Game.set_setting(key, v))
	box.add_child(s)
	return s


func _toggle(text: String, key: String) -> CheckButton:
	var c := CheckButton.new()
	c.text = text
	c.button_pressed = bool(Game.settings[key])
	c.custom_minimum_size = Vector2(0, 64)
	c.toggled.connect(func(on): Game.set_setting(key, on))
	box.add_child(c)
	return c


func _confirm_reset() -> void:
	var d := ConfirmationDialog.new()
	d.title = "Reset progress?"
	d.dialog_text = "This deletes all XP, streak, coins and word progress on this device. It can't be undone (unless you exported a backup)."
	d.dialog_autowrap = true
	d.size = Vector2i(460, 280)
	d.ok_button_text = "Reset"
	d.confirmed.connect(func():
		Game.reset_progress()
		retake_placement.emit())
	add_child(d)
	d.popup_centered()


func _voice_check() -> void:
	var sp := Game.speech()
	var lines: Array = []
	if sp == null:
		lines.append("Speech module missing.")
	else:
		var r: Dictionary = sp.debug_report()
		lines.append("Afrikaans voice: %s %s" % ["YES" if sp.has_afrikaans else "no", sp.voice_name])
		lines.append(JSON.stringify(r, " ").left(1500))
		Game.speak("Goeiemôre! Hoe gaan dit met jou?")
	_say("\n".join(lines))
