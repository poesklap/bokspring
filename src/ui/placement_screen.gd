extends Control
## Skippable adaptive placement test (~12 questions, about 2 minutes).
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
	U.label(box, "Let's see how much Afrikaans comes back to you. About 12 quick questions, 2 minutes. It sets your starting level; you can change it any time in settings.", "", true)
	U.spacer(box)
	U.button(box, "Begin  (start)", _begin)
	U.button(box, "Skip: start at Elementary", func(): _finish(Difficulty.ELEMENTARY), "GhostButton")


func _begin() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	test = Placement.new(Game.content.placement, rng)
	_next()


func _next() -> void:
	q = test.next_question()
	if q.is_empty():
		_result()
		return
	_reset()
	var bar := ProgressBar.new()
	bar.max_value = Placement.LENGTH
	bar.value = test.asked
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 16)
	box.add_child(bar)
	U.label(box, "What does this mean?", "MutedLabel", true)
	var p := U.label(box, str(q.prompt), "TitleLabel", true)
	p.custom_minimum_size = Vector2(0, 140)
	p.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	Game.speak(str(q.promptAudio))
	for i in q.options.size():
		var idx: int = i
		U.button(box, str(q.options[i]), func(): _answer(idx), "SecondaryButton")
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
		"intermediate": "Around Grade 10–11: faster, trickier wrong answers.",
		"advanced": "Matric level: quick pace and close look-alikes.",
	}
	U.label(box, blurb[level], "MutedLabel", true)
	U.spacer(box)
	U.button(box, "Gaan voort  (continue)", func(): _finish(level))


func _finish(level: String) -> void:
	Game.engine.set_difficulty(level)
	Game.engine.progress.placementDone = true
	Game.save()
	finished.emit(level)
