extends Control
## Skippable adaptive placement test: starts with the hardest sentences and
## falls back level by level (see src/engine/placement.gd).
## Skipping sets Elementary: the learner has studied Afrikaans before.

const U = preload("res://src/ui/ui_util.gd")
const Placement = preload("res://src/engine/placement.gd")
const Difficulty = preload("res://src/engine/difficulty.gd")

signal finished(level: String)

var first_time := true
var test: Placement
var box: VBoxContainer
var q: Dictionary


func _ready() -> void:
	_intro()


func _reset() -> void:
	for c in get_children():
		c.queue_free()
	box = U.page(self)


func _intro() -> void:
	_reset()
	U.label(box, "Welkom!" if first_time else "Placement test", "TitleLabel", true)
	var hero := U.icon("res://assets/springbok/hero.svg", 220)
	hero.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(hero)
	U.label(box, "Let's see how much Afrikaans comes back to you. We start with hard sentences and make them easier until we find your level. Up to 2 minutes; you can change the level any time in settings.", "", true)
	U.spacer(box)
	U.button(box, "Begin  (start)", _begin)
	U.button(box, "Skip: start at Elementary", func(): _finish(Difficulty.ELEMENTARY), "GhostButton")


func _begin() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	test = Placement.new(Placement.build_bank(Game.content.placement, Game.content.items), rng)
	_next()


func _next() -> void:
	q = test.next_question()
	if q.is_empty():
		_result()
		return
	_reset()
	var level_names := {4: "Grade 11–12 sentences", 3: "Grade 8–9 sentences", 2: "Everyday Afrikaans", 1: "The basics"}
	U.label(box, "Question %d  ·  %s" % [test.asked + 1, level_names[int(q.tier)]], "MutedLabel", true)
	U.label(box, "What does this mean?", "MutedLabel", true)
	var p := U.label(box, str(q.prompt), "TitleLabel" if str(q.prompt).length() <= 30 else "", true)
	if str(q.prompt).length() > 30:
		p.add_theme_font_size_override("font_size", 30 if str(q.prompt).length() <= 90 else 26)
	p.custom_minimum_size = Vector2(0, 140)
	p.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	Game.speak(str(q.promptAudio))
	for i in q.options.size():
		var idx: int = i
		var b := U.button(box, str(q.options[i]), func(): _answer(idx), "SecondaryButton")
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if str(q.options[i]).length() > 30:
			b.add_theme_font_size_override("font_size", 22)
	U.spacer(box)
	U.button(box, "I don't know", func(): _answer(-1), "GhostButton")
	U.button(box, "Skip the test", func(): _finish(Difficulty.ELEMENTARY), "GhostButton")


func _answer(i: int) -> void:
	var correct := i == int(q.correctIndex)
	Game.play_sfx("correct" if correct else "wrong")
	test.answer(correct)
	_next()


func _result() -> void:
	var level := test.result_level()
	_reset()
	U.label(box, "Mooi so!", "TitleLabel", true)
	U.label(box, "You're starting at", "", true)
	U.label(box, str(Difficulty.profile(level).label), "HugeLabel", true)
	var blurb := {
		"beginner": "We'll start with the basics at a gentle pace.",
		"elementary": "Around Grade 7–9 level, at a steady pace.",
		"intermediate": "Grade 8–9 Home Language sentences from the start, with harder ones as you master them.",
		"advanced": "Grade 11–12 Home Language sentences, quick pace and close look-alikes.",
	}
	U.label(box, blurb[level], "MutedLabel", true)
	U.spacer(box)
	U.button(box, "Gaan voort  (continue)", func(): _finish(level))


func _finish(level: String) -> void:
	Game.engine.set_difficulty(level)
	Game.engine.progress.placementDone = true
	Game.save()
	finished.emit(level)
