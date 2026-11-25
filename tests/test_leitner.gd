extends RefCounted
const Leitner = preload("res://src/engine/leitner.gd")
var t


func test_new_card_starts_in_box_1_due_today() -> void:
	var c := Leitner.new_card(100)
	t.eq(c.box, 1, "box")
	t.ok(Leitner.is_due(c, 100), "due today")


func test_correct_moves_up_one_box_with_interval() -> void:
	var c := Leitner.new_card(100)
	c = Leitner.apply_answer(c, true, 100)
	t.eq(c.box, 2, "box after 1st correct")
	t.eq(c.dueDay, 101, "box 2 due in 1 day")
	c = Leitner.apply_answer(c, true, 101)
	t.eq(c.box, 3, "box 3")
	t.eq(c.dueDay, 104, "box 3 due in 3 days")
	c = Leitner.apply_answer(c, true, 104)
	t.eq(c.box, 4, "box 4")
	t.eq(c.dueDay, 111, "box 4 due in 7 days")
	c = Leitner.apply_answer(c, true, 111)
	t.eq(c.box, 5, "box 5")
	t.eq(c.dueDay, 132, "box 5 due in 21 days")
	t.ok(Leitner.is_mastered(c), "mastered at box 5")


func test_box_5_stays_at_5() -> void:
	var c := {"box": 5, "dueDay": 10}
	c = Leitner.apply_answer(c, true, 10)
	t.eq(c.box, 5, "stays 5")
	t.eq(c.dueDay, 31, "re-scheduled 21 days")


func test_wrong_sends_to_box_1_due_same_session() -> void:
	var c := {"box": 4, "dueDay": 50}
	c = Leitner.apply_answer(c, false, 50)
	t.eq(c.box, 1, "back to box 1")
	t.eq(c.dueDay, 50, "due again today")
	t.eq(c.lastWrongDay, 50, "last wrong recorded")


func test_early_review_correct_does_not_promote() -> void:
	var c := {"box": 3, "dueDay": 20}
	c = Leitner.apply_answer(c, true, 15)
	t.eq(c.box, 3, "no promotion when not due")
	t.eq(c.dueDay, 20, "due date unchanged")


func test_early_review_wrong_still_demotes() -> void:
	var c := {"box": 3, "dueDay": 20}
	c = Leitner.apply_answer(c, false, 15)
	t.eq(c.box, 1, "demoted")


func test_apply_does_not_mutate_input() -> void:
	var c := Leitner.new_card(1)
	var c2 := Leitner.apply_answer(c, true, 1)
	t.eq(c.box, 1, "original unchanged")
	t.eq(c2.box, 2, "copy changed")


func test_json_floats_are_handled() -> void:
	# Saved progress comes back from JSON with floats.
	var c := {"box": 2.0, "dueDay": 7.0, "seen": 1.0, "correct": 1.0, "wrong": 0.0}
	c = Leitner.apply_answer(c, true, 7)
	t.eq(c.box, 3, "float box")
	t.eq(c.dueDay, 10, "float due")
