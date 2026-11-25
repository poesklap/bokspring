extends RefCounted
## The learner's progress: XP, daily goal, streak (with weekly freeze),
## word cards and stats. Belongs to the learner, not to any game skin.
## Plain Dictionary so it can be saved as JSON and reused by future skins.

const Clock = preload("res://src/engine/clock.gd")

const VERSION := 1
const GOAL_ROUNDS := 3
const GOAL_XP := 50


static func create(today: int) -> Dictionary:
	return {
		"version": VERSION,
		"createdDay": today,
		"difficulty": "elementary",
		"placementDone": false,
		"xp": 0,
		"cards": {},
		"stats": {"answers": 0, "correct": 0, "totalMs": 0, "rounds": 0},
		"daily": {"day": today, "xp": 0, "rounds": 0, "newCount": 0, "goalMet": false},
		"streak": {"count": 0, "lastGoalDay": -10, "freezeUsedWeek": -1, "best": 0},
		"seenTips": [],
	}


## Fills in any missing keys (older saves, hand-edited imports).
static func normalise(p: Dictionary, today: int) -> Dictionary:
	var base := create(today)
	for k in base:
		if not p.has(k) or typeof(p[k]) != typeof(base[k]):
			p[k] = base[k]
		elif base[k] is Dictionary:
			for k2 in base[k]:
				if not p[k].has(k2):
					p[k][k2] = base[k][k2]
	return p


static func roll_day(p: Dictionary, today: int) -> void:
	if int(p.daily.day) != today:
		p.daily = {"day": today, "xp": 0, "rounds": 0, "newCount": 0, "goalMet": false}


static func add_xp(p: Dictionary, amount: int, today: int) -> void:
	roll_day(p, today)
	p.xp = int(p.xp) + amount
	p.daily.xp = int(p.daily.xp) + amount
	_check_goal(p, today)


static func complete_round(p: Dictionary, today: int) -> void:
	roll_day(p, today)
	p.daily.rounds = int(p.daily.rounds) + 1
	p.stats.rounds = int(p.stats.rounds) + 1
	_check_goal(p, today)


static func goal_progress(p: Dictionary, today: int) -> float:
	roll_day(p, today)
	return clampf(maxf(float(p.daily.rounds) / GOAL_ROUNDS, float(p.daily.xp) / GOAL_XP), 0.0, 1.0)


static func _check_goal(p: Dictionary, today: int) -> void:
	if p.daily.goalMet:
		return
	if int(p.daily.rounds) >= GOAL_ROUNDS or int(p.daily.xp) >= GOAL_XP:
		p.daily.goalMet = true
		_extend_streak(p, today)


## Hitting the daily goal extends the streak. One missed day per week is
## covered by a free streak freeze.
static func _extend_streak(p: Dictionary, today: int) -> void:
	var s: Dictionary = p.streak
	var last := int(s.lastGoalDay)
	if last == today:
		return
	if last == today - 1:
		s.count = int(s.count) + 1
	elif last == today - 2 and freeze_available(p, today - 1):
		s.freezeUsedWeek = Clock.week_index(today - 1)
		s.count = int(s.count) + 1
	else:
		s.count = 1
	s.lastGoalDay = today
	s.best = maxi(int(s.best), int(s.count))


static func freeze_available(p: Dictionary, missed_day: int) -> bool:
	return int(p.streak.freezeUsedWeek) != Clock.week_index(missed_day)


## The streak as it stands today (0 if it has lapsed).
static func current_streak(p: Dictionary, today: int) -> int:
	var last := int(p.streak.lastGoalDay)
	if last >= today - 1:
		return int(p.streak.count)
	if last == today - 2 and freeze_available(p, today - 1):
		return int(p.streak.count)
	return 0


static func record_answer(p: Dictionary, correct: bool, response_ms: int) -> void:
	p.stats.answers = int(p.stats.answers) + 1
	if correct:
		p.stats.correct = int(p.stats.correct) + 1
	p.stats.totalMs = int(p.stats.totalMs) + maxi(0, response_ms)


static func count_by_box(p: Dictionary) -> Array:
	var counts := [0, 0, 0, 0, 0]
	for id in p.cards:
		counts[clampi(int(p.cards[id].box), 1, 5) - 1] += 1
	return counts
