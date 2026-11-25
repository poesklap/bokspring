class_name LearningEngine
extends RefCounted
## The learning engine shared by every skin. Decides WHAT to ask; a skin
## decides how it looks. No rendering code here.
##
## Use:  start_round() -> next_challenge() -> report_result(...) -> ... -> round_summary()

const Leitner = preload("res://src/engine/leitner.gd")
const Scheduler = preload("res://src/engine/scheduler.gd")
const ChallengeGen = preload("res://src/engine/challenge_gen.gd")
const RoundSession = preload("res://src/engine/round_session.gd")
const Progress = preload("res://src/engine/progress.gd")
const Difficulty = preload("res://src/engine/difficulty.gd")

const XP_PER_CORRECT := 10
const XP_ROUND_BONUS := 20

var items: Dictionary = {}       # id -> item
var items_in_order: Array = []
var units: Array = []            # from units.json
var progress: Dictionary
var today: int
var rng := RandomNumberGenerator.new()
var session: RoundSession
var listening_enabled := false   # set by the host when the device has an Afrikaans voice
var _cid := 0
var _current: Dictionary = {}
var _round_xp := 0


## content: {"items": Array, "units": Array}; progress_data from storage (or {}).
func _init(content: Dictionary, progress_data: Dictionary, today_day: int, seed_value: int = 0) -> void:
	today = today_day
	if seed_value != 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	units = content.get("units", [])
	for it in content.get("items", []):
		items[it.id] = it
		items_in_order.append(it)
	progress = Progress.normalise(progress_data if not progress_data.is_empty() else Progress.create(today), today)


func set_today(day: int) -> void:
	today = day
	Progress.roll_day(progress, today)


func profile() -> Dictionary:
	return Difficulty.profile(str(progress.difficulty))


func set_difficulty(level: String) -> void:
	if Difficulty.PROFILES.has(level):
		progress.difficulty = level


## Units are unlocked by difficulty level or by XP.
func unlocked_units() -> Array:
	var out: Array = []
	var max_by_level := int(profile().maxUnlockedUnit)
	for u in units:
		if int(u.id) <= max_by_level or int(progress.xp) >= int(u.get("xpToUnlock", 0)):
			out.append(int(u.id))
	if out.is_empty() and not units.is_empty():
		out.append(int(units[0].id))
	return out


## The next locked unit and the XP it needs, or {} if all are open.
func next_unlock() -> Dictionary:
	var open := unlocked_units()
	for u in units:
		if not open.has(int(u.id)):
			return {"unit": u, "xpNeeded": maxi(0, int(u.xpToUnlock) - int(progress.xp))}
	return {}


## Hardest sentence tier that may be introduced now. Advanced (matric) learners
## get everything; others unlock tier 4 once tier 3 sentences are known.
func max_sentence_tier() -> int:
	if str(progress.difficulty) == Difficulty.ADVANCED:
		return 4
	return Scheduler.max_new_tier(items_in_order, progress.cards)


func start_round(size: int = 10) -> void:
	Progress.roll_day(progress, today)
	var ids := Scheduler.select(items_in_order, progress.cards, unlocked_units(),
		int(profile().startUnit), today, int(progress.daily.newCount), size,
		max_sentence_tier(), bool(profile().get("sentencesEarly", false)))
	session = RoundSession.new(ids)
	_round_xp = 0
	_current = {}


## Starts a session made only of the given items (e.g. the Foute deck, M2).
func start_custom_round(ids: Array) -> void:
	session = RoundSession.new(ids)
	_round_xp = 0
	_current = {}


## Next challenge, or {} when the session is complete.
func next_challenge() -> Dictionary:
	if session == null:
		start_round()
	var id := session.next_item()
	if id == "" or not items.has(id):
		_current = {}
		return {}
	var item: Dictionary = items[id]
	var card: Dictionary = progress.cards.get(id, {})
	var box := int(card.get("box", 1))
	var p := profile()
	var type := ChallengeGen.TYPE_AF_EN
	if not card.is_empty() and box >= int(p.reverseFromBox) and rng.randf() < float(p.reverseChance):
		type = ChallengeGen.TYPE_EN_AF
	if listening_enabled and not card.is_empty() and box >= 2 and rng.randf() < 0.2:
		type = ChallengeGen.TYPE_LISTEN
	_cid += 1
	_current = ChallengeGen.build(item, type, _pool_for(item), int(p.lanes),
		float(p.similarity), box, float(p.speed), rng, "c_%04d" % _cid)
	_current["isNew"] = card.is_empty()
	return _current


func _pool_for(item: Dictionary) -> Array:
	# Prefer distractors from unlocked units, but allow any if that's too few.
	var open := unlocked_units()
	var pool: Array = []
	for it in items_in_order:
		if open.has(int(it.unit)):
			pool.append(it)
	if pool.size() < 6:
		pool = items_in_order
	return pool


## Updates the box, XP and stats. Returns what the skin needs to react.
func report_result(item_id: String, correct: bool, response_ms: int) -> Dictionary:
	Progress.roll_day(progress, today)
	var is_new: bool = not progress.cards.has(item_id)
	var card: Dictionary = progress.cards.get(item_id, Leitner.new_card(today))
	# A new word answered right on first sight was already known (returning
	# learner), so it doesn't use up the daily new-word allowance.
	if is_new and not correct:
		progress.daily.newCount = int(progress.daily.newCount) + 1
	card = Leitner.apply_answer(card, correct, today)
	progress.cards[item_id] = card
	Progress.record_answer(progress, correct, response_ms)

	var xp := 0
	var was_complete := false
	if session != null and session.current_item() == item_id:
		session.record(correct)
		was_complete = session.is_complete()
	if correct:
		xp = XP_PER_CORRECT * (session.multiplier() if session != null else 1)
	if was_complete:
		xp += XP_ROUND_BONUS
		Progress.complete_round(progress, today)
	if xp > 0:
		Progress.add_xp(progress, xp, today)
	_round_xp += xp
	_current = {}
	return {
		"correct": correct,
		"xp": xp,
		"box": int(card.box),
		"combo": session.combo if session != null else 0,
		"multiplier": session.multiplier() if session != null else 1,
		"roundComplete": was_complete,
		"remaining": (session.size() - session.done_count()) if session != null else 0,
	}


func round_summary() -> Dictionary:
	if session == null:
		return {}
	return {
		"size": session.size(),
		"answered": session.answered,
		"correct": session.correct_count,
		"wrong": session.wrong_count,
		"bestCombo": session.best_combo,
		"xp": _round_xp,
		"missed": session.missed_items.duplicate(),
		"complete": session.is_complete(),
	}


func streak() -> int:
	return Progress.current_streak(progress, today)


func goal_progress() -> float:
	return Progress.goal_progress(progress, today)


func item(id: String) -> Dictionary:
	return items.get(id, {})
