extends RefCounted
const Scheduler = preload("res://src/engine/scheduler.gd")
const RoundSession = preload("res://src/engine/round_session.gd")
var t


func _items(n: int, unit := 1) -> Array:
	var out: Array = []
	for i in n:
		out.append({"id": "w_%d_%02d" % [unit, i], "unit": unit, "tier": 1, "kind": "word"})
	return out


func test_day_one_only_new_items_capped_at_8() -> void:
	var items := _items(30)
	var ids := Scheduler.select(items, {}, [1], 1, 100, 0, 10)
	t.eq(ids.size(), 10, "always 10 slots")
	var uniq := {}
	for id in ids:
		uniq[id] = true
	t.eq(uniq.size(), 8, "8 distinct new words, 2 repeats")


func test_new_cap_respects_words_already_introduced_today() -> void:
	var items := _items(30)
	var ids := Scheduler.select(items, {}, [1], 1, 100, 8, 10)
	t.eq(ids.size(), 0, "no items when cap used and nothing learned yet")


func test_mix_is_70_20_10_when_everything_available() -> void:
	var items := _items(60)
	var cards := {}
	for i in 30:  # due reviews
		cards[items[i].id] = {"box": 2, "dueDay": 99, "lastWrongDay": -1}
	for i in range(30, 40):  # recent mistakes
		cards[items[i].id] = {"box": 1, "dueDay": 100, "lastWrongDay": 99}
	var ids := Scheduler.select(items, cards, [1], 1, 100, 0, 10)
	var due := 0
	var mis := 0
	var fresh := 0
	for id in ids:
		var n := int(id.split("_")[2])
		if n < 30: due += 1
		elif n < 40: mis += 1
		else: fresh += 1
	t.eq(due, 7, "7 due")
	t.eq(fresh, 2, "2 new")
	t.eq(mis, 1, "1 mistake")


func test_due_lowest_box_first_and_not_due_excluded_when_enough() -> void:
	var items := _items(20)
	var cards := {}
	for i in 12:
		cards[items[i].id] = {"box": 2 + (i % 3), "dueDay": 100, "lastWrongDay": -1}
	for i in range(12, 20):
		cards[items[i].id] = {"box": 3, "dueDay": 150, "lastWrongDay": -1}
	var ids := Scheduler.select(items, cards, [1], 1, 100, 8, 10)
	for id in ids:
		t.ok(int(id.split("_")[2]) < 12, "only due items: %s" % id)


func test_fills_with_early_review_when_nothing_due() -> void:
	var items := _items(10)
	var cards := {}
	for it in items:
		cards[it.id] = {"box": 3, "dueDay": 120, "lastWrongDay": -1}
	var ids := Scheduler.select(items, cards, [1], 1, 100, 8, 10)
	t.eq(ids.size(), 10, "filled from early review")


func test_locked_units_are_excluded() -> void:
	var items := _items(5, 1) + _items(5, 2)
	var ids := Scheduler.select(items, {}, [1], 1, 100, 0, 10)
	for id in ids:
		t.ok(id.begins_with("w_1_"), "unit 2 locked: %s" % id)


func test_new_items_start_from_starting_unit() -> void:
	var items := _items(10, 1) + _items(10, 2)
	var ids := Scheduler.select(items, {}, [1, 2], 2, 100, 0, 10)
	t.ok(ids[0].begins_with("w_2_"), "starts at unit 2")


func test_round_requeues_missed_item_later_in_same_round() -> void:
	var r := RoundSession.new(["a", "b", "c", "d"])
	t.eq(r.next_item(), "a", "first")
	r.record(false)
	t.eq(r.next_item(), "b", "b next")
	r.record(true)
	t.eq(r.next_item(), "c", "c next")
	r.record(true)
	t.eq(r.next_item(), "a", "a comes back after 2")
	r.record(true)
	t.eq(r.next_item(), "d", "d last")
	t.ok(not r.is_complete(), "not complete before last answer")
	r.record(true)
	t.ok(r.is_complete(), "complete when all answered correctly")
	t.eq(r.next_item(), "", "nothing left")
	t.eq(r.missed_items, ["a"], "missed list")


func test_round_complete_needs_every_slot_correct() -> void:
	var r := RoundSession.new(["a", "b"])
	r.next_item(); r.record(true)
	r.next_item(); r.record(false)
	t.ok(not r.is_complete(), "b still open")
	t.eq(r.next_item(), "b", "b again")
	r.record(true)
	t.ok(r.is_complete(), "done")


func test_combo_multiplier() -> void:
	t.eq(RoundSession.multiplier_for(4), 1, "x1 under 5")
	t.eq(RoundSession.multiplier_for(5), 2, "x2 at 5")
	t.eq(RoundSession.multiplier_for(9), 2, "x2 at 9")
	t.eq(RoundSession.multiplier_for(10), 3, "x3 at 10")
	var r := RoundSession.new(["a", "b", "c", "d", "e", "f"])
	for i in 5:
		r.next_item(); r.record(true)
	t.eq(r.multiplier(), 2, "x2 after 5 in a row")
	r.next_item(); r.record(false)
	t.eq(r.combo, 0, "combo reset on mistake")
	t.eq(r.best_combo, 5, "best combo kept")


func _phrases(n: int, tier: int, prefix: String) -> Array:
	var out: Array = []
	for i in n:
		out.append({"id": "p_%s_%02d" % [prefix, i], "unit": 1, "tier": tier, "kind": "phrase"})
	return out


func test_tier4_sentences_wait_until_tier3_known() -> void:
	var t3 := _phrases(12, 3, "a")
	var t4 := _phrases(8, 4, "b")
	var items := t3 + t4
	t.eq(Scheduler.max_new_tier(items, {}), 3, "nothing known yet: tier 3 only")
	var ids := Scheduler.select(items, {}, [1], 1, 100, 0, 10, Scheduler.max_new_tier(items, {}))
	for id in ids:
		t.ok(id.begins_with("p_a_"), "no tier 4 yet: %s" % id)
	var cards := {}
	for i in 9:
		cards[t3[i].id] = {"box": 3, "dueDay": 200, "lastWrongDay": -1}
	t.eq(Scheduler.max_new_tier(items, cards), 3, "9 known: still 3")
	cards[t3[9].id] = {"box": 4, "dueDay": 200, "lastWrongDay": -1}
	t.eq(Scheduler.max_new_tier(items, cards), 4, "10 known: tier 4 opens")
	var later := Scheduler.select(items, cards, [1], 1, 100, 0, 10, 4)
	var has4 := false
	for id in later:
		if id.begins_with("p_b_"):
			has4 = true
	t.ok(has4, "tier 4 sentences now introduced")


func test_tier_gate_never_blocks_words() -> void:
	var words: Array = [{"id": "w_hard", "unit": 1, "tier": 4, "kind": "word"}]
	var ids := Scheduler.select(words, {}, [1], 1, 100, 0, 1, 3)
	t.eq(ids, ["w_hard"], "tier 4 word still taught")


func test_sentence_level_learners_get_sentences_from_the_start() -> void:
	var items := _items(10) + _phrases(5, 3, "s")
	var normal := Scheduler.select(items, {}, [1], 1, 100, 0, 10, 4, false)
	for id in normal:
		t.ok(id.begins_with("w_"), "words first normally: %s" % id)
	var early := Scheduler.select(items, {}, [1], 1, 100, 0, 10, 4, true)
	t.ok(early.has("p_s_00") and early.has("w_1_00"), "sentences and words mixed: %s" % str(early))
