extends RefCounted
const Progress = preload("res://src/engine/progress.gd")
const Placement = preload("res://src/engine/placement.gd")
const Clock = preload("res://src/engine/clock.gd")
var t


func _content(n := 30) -> Dictionary:
	var items: Array = []
	var words := ["hond", "hand", "huis", "kat", "perd", "koei", "vis", "brood", "kaas", "melk",
		"rooi", "blou", "groen", "geel", "swart", "wit", "een", "twee", "drie", "vier",
		"vyf", "ses", "sewe", "agt", "nege", "tien", "appel", "piesang", "water", "tee"]
	for i in n:
		items.append({"id": "w_%s" % words[i], "af": words[i], "en": "en_%s" % words[i],
			"unit": 1 + (i % 2), "category": "c%d" % (i % 3), "kind": "word", "partOfSpeech": "noun", "tier": 1})
	return {"items": items, "units": [{"id": 1, "xpToUnlock": 0}, {"id": 2, "xpToUnlock": 150}]}


func test_streak_extends_on_consecutive_goal_days() -> void:
	var p := Progress.create(1000)
	Progress.add_xp(p, 50, 1000)
	t.eq(Progress.current_streak(p, 1000), 1, "day 1")
	Progress.complete_round(p, 1001)
	Progress.complete_round(p, 1001)
	t.eq(Progress.current_streak(p, 1001), 1, "goal not met yet: streak still 1")
	Progress.complete_round(p, 1001)
	t.eq(Progress.current_streak(p, 1001), 2, "3 rounds -> day 2")


func test_goal_met_only_counts_once_per_day() -> void:
	var p := Progress.create(1000)
	Progress.add_xp(p, 60, 1000)
	Progress.add_xp(p, 60, 1000)
	for i in 5:
		Progress.complete_round(p, 1000)
	t.eq(int(p.streak.count), 1, "once per day")


func test_streak_freeze_covers_one_missed_day_per_week() -> void:
	# Day 1000 is a Monday? Compute a Monday to keep weeks predictable.
	var monday := 1000
	while Clock.week_index(monday) == Clock.week_index(monday - 1):
		monday += 1
	var p := Progress.create(monday)
	Progress.add_xp(p, 50, monday)             # Mon
	Progress.add_xp(p, 50, monday + 1)         # Tue
	# Wed missed
	t.eq(Progress.current_streak(p, monday + 3), 2, "freeze keeps streak visible on Thu")
	Progress.add_xp(p, 50, monday + 3)         # Thu (freeze used for Wed)
	t.eq(Progress.current_streak(p, monday + 3), 3, "streak continues")
	# Fri missed: second miss in the same week is not covered
	Progress.add_xp(p, 50, monday + 5)         # Sat
	t.eq(Progress.current_streak(p, monday + 5), 1, "second miss same week resets")


func test_streak_lapses_after_two_missed_days() -> void:
	var p := Progress.create(500)
	Progress.add_xp(p, 50, 500)
	t.eq(Progress.current_streak(p, 503), 0, "lapsed")


func test_normalise_fills_missing_keys() -> void:
	var p := Progress.normalise({"xp": 40}, 10)
	t.eq(int(p.xp), 40, "keeps xp")
	t.ok(p.has("cards") and p.has("streak") and p.daily.has("newCount"), "filled")


func test_engine_full_round_updates_boxes_xp_and_completes() -> void:
	var e := LearningEngine.new(_content(), {}, 2000, 42)
	e.start_round(10)
	var answers := 0
	var wrong_given := false
	while true:
		var c := e.next_challenge()
		if c.is_empty():
			break
		t.ok(c.options.size() >= 2, "options present")
		t.ok(c.correctIndex >= 0 and c.correctIndex < c.options.size(), "valid index")
		var correct := true
		if not wrong_given:
			correct = false
			wrong_given = true
		var r := e.report_result(c.itemId, correct, 1500)
		answers += 1
		t.ok(answers < 40, "terminates")
		if answers >= 40:
			break
	var s := e.round_summary()
	t.ok(s.complete, "round complete")
	t.eq(s.wrong, 1, "one wrong")
	t.eq(s.answered, 11, "10 slots + 1 retry")
	t.ok(int(e.progress.xp) > 0, "xp gained")
	t.eq(int(e.progress.daily.rounds), 1, "round counted")
	var missed: String = s.missed[0]
	t.eq(int(e.progress.cards[missed].box), 2, "missed then right: box 1 -> 2")


func test_engine_xp_uses_combo_multiplier_and_round_bonus() -> void:
	var e := LearningEngine.new(_content(), {}, 2000, 7)
	e.start_round(10)
	var total := 0
	var last := {}
	while true:
		var c := e.next_challenge()
		if c.is_empty():
			break
		last = e.report_result(c.itemId, true, 1000)
		total += int(last.xp)
	# 4x10 + 5x20 (x2 from combo 5..9) + 1x30 (x3 at 10) + 20 bonus
	t.eq(total, 40 + 100 + 30 + 20, "xp total")
	t.ok(last.roundComplete, "last result flags completion")


func test_engine_unlocks_units_by_xp() -> void:
	var e := LearningEngine.new(_content(), {"difficulty": "beginner"}, 2000, 1)
	t.eq(e.unlocked_units(), [1], "beginner: unit 1")
	e.progress.xp = 150
	t.eq(e.unlocked_units(), [1, 2], "150 xp unlocks unit 2")


func test_recalled_new_words_do_not_use_new_allowance() -> void:
	var e := LearningEngine.new(_content(), {"difficulty": "advanced"}, 2000, 3)
	e.start_round(10)
	while true:
		var c := e.next_challenge()
		if c.is_empty():
			break
		e.report_result(c.itemId, true, 900)
	t.eq(int(e.progress.daily.newCount), 0, "all recalled on first sight")
	e.start_round(10)
	var c2 := e.next_challenge()
	t.ok(c2.isNew, "more new words offered after fast wins")


func test_placement_strong_player_reaches_advanced() -> void:
	var qs := _placement_bank()
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var pt := Placement.new(qs, rng)
	var n := 0
	while not pt.is_done():
		var q := pt.next_question()
		if q.is_empty():
			break
		t.ok(q.options[q.correctIndex] == "right", "correct index tracks shuffle")
		pt.answer(true)
		n += 1
	t.eq(n, 12, "12 questions")
	t.eq(pt.result_level(), "advanced", "all right -> advanced")


func test_placement_weak_player_is_beginner() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var pt := Placement.new(_placement_bank(), rng)
	while not pt.is_done():
		if pt.next_question().is_empty():
			break
		pt.answer(false)
	t.eq(pt.result_level(), "beginner", "all wrong -> beginner")


func test_placement_middle_player() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	var pt := Placement.new(_placement_bank(), rng)
	while not pt.is_done():
		var q := pt.next_question()
		if q.is_empty():
			break
		pt.answer(int(q.tier) <= 2)  # knows tiers 1-2 only
	t.eq(pt.result_level(), "elementary", "knows basics -> elementary")


func _placement_bank() -> Array:
	var qs: Array = []
	for tier in range(1, 5):
		for i in 8:
			qs.append({"id": "pl_%d_%d" % [tier, i], "tier": tier, "prompt": "p",
				"options": ["right", "w1", "w2", "w3"], "correctIndex": 0})
	return qs
