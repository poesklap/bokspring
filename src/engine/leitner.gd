extends RefCounted
## Leitner spaced repetition: 5 boxes per item. Pure data, no UI.
##
## Correct moves an item up one box (only when it was due, so early reviews
## don't inflate mastery). Wrong sends it back to box 1.
## Box intervals: same session, 1 day, 3 days, 7 days, 21 days.
## Time is measured in whole local days ("day index"), see clock.gd.

const MAX_BOX := 5
const INTERVAL_DAYS := [0, 1, 3, 7, 21]


static func interval_for(box: int) -> int:
	return INTERVAL_DAYS[clampi(box, 1, MAX_BOX) - 1]


static func new_card(today: int) -> Dictionary:
	return {
		"box": 1,
		"dueDay": today,
		"seen": 0,
		"correct": 0,
		"wrong": 0,
		"introducedDay": today,
		"lastDay": -1,
		"lastWrongDay": -1,
	}


static func is_due(card: Dictionary, today: int) -> bool:
	return int(card.get("dueDay", 0)) <= today


static func is_mastered(card: Dictionary) -> bool:
	return int(card.get("box", 1)) >= MAX_BOX


## Returns a new card dictionary; the input is not modified.
static func apply_answer(card: Dictionary, correct: bool, today: int) -> Dictionary:
	var c: Dictionary = card.duplicate()
	var was_due := is_due(c, today)
	var box := int(c.get("box", 1))
	c["seen"] = int(c.get("seen", 0)) + 1
	c["lastDay"] = today
	if correct:
		c["correct"] = int(c.get("correct", 0)) + 1
		if was_due:
			box = mini(box + 1, MAX_BOX)
			c["dueDay"] = today + interval_for(box)
	else:
		c["wrong"] = int(c.get("wrong", 0)) + 1
		box = 1
		c["dueDay"] = today
		c["lastWrongDay"] = today
	c["box"] = box
	return c
