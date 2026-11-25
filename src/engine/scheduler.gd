extends RefCounted
## Chooses which items go into a round.
## Mix per round: ~70% due reviews, ~20% new items, ~10% recent mistakes.
## At most DAILY_NEW_LIMIT genuinely new words a day. Shortfalls are filled
## from the other groups, then from early review of not-yet-due items, and
## finally by repeating items already in the round.

const Leitner = preload("res://src/engine/leitner.gd")

const DAILY_NEW_LIMIT := 8
const MISTAKE_DAYS := 2   # "recent" = wrong within the last 2 days
const SHARE_DUE := 0.7
const SHARE_NEW := 0.2


## items_in_order: content items in teaching order (unit, then file order).
## Returns an Array of item ids, length n (may contain repeats if content is thin).
static func select(items_in_order: Array, cards: Dictionary, unlocked_units: Array,
		start_unit: int, today: int, new_used_today: int, n: int, max_new_tier: int = 4,
		sentences_early: bool = false) -> Array:
	var unlocked := {}
	for u in unlocked_units:
		unlocked[int(u)] = true

	var mistakes: Array = []
	var due: Array = []
	var early: Array = []
	var fresh: Array = []
	for item in items_in_order:
		var id: String = item.id
		if not unlocked.has(int(item.unit)):
			continue
		if not cards.has(id):
			# Only sentences are held back by tier; words are always teachable.
			if str(item.get("kind", "")) != "phrase" or int(item.get("tier", 1)) <= max_new_tier:
				fresh.append(item)
			continue
		var c: Dictionary = cards[id]
		if int(c.get("lastWrongDay", -1)) >= today - MISTAKE_DAYS and int(c.get("box", 1)) <= 2:
			mistakes.append(id)
		elif Leitner.is_due(c, today):
			due.append(id)
		else:
			early.append(id)

	# Due: lowest box and most overdue first.
	due.sort_custom(func(a, b):
		var ca: Dictionary = cards[a]
		var cb: Dictionary = cards[b]
		if int(ca.box) != int(cb.box):
			return int(ca.box) < int(cb.box)
		return int(ca.dueDay) < int(cb.dueDay))
	mistakes.sort_custom(func(a, b): return int(cards[a].lastWrongDay) > int(cards[b].lastWrongDay))
	early.sort_custom(func(a, b):
		var ca: Dictionary = cards[a]
		var cb: Dictionary = cards[b]
		if int(ca.dueDay) != int(cb.dueDay):
			return int(ca.dueDay) < int(cb.dueDay)
		return int(ca.box) < int(cb.box))

	# New items: from the starting unit upwards, then earlier units; lower tier first.
	fresh.sort_custom(func(a, b):
		var ka := _unit_rank(int(a.unit), start_unit)
		var kb := _unit_rank(int(b.unit), start_unit)
		if ka != kb:
			return ka < kb
		return int(a.get("tier", 1)) < int(b.get("tier", 1)))
	# Learners placed at sentence level get new sentences alternating with new
	# words from the start, instead of only after a unit's words.
	if sentences_early:
		var sents: Array = fresh.filter(func(it): return str(it.get("kind", "")) == "phrase")
		var words: Array = fresh.filter(func(it): return str(it.get("kind", "")) != "phrase")
		fresh = []
		while not sents.is_empty() or not words.is_empty():
			if not sents.is_empty():
				fresh.append(sents.pop_front())
			if not words.is_empty():
				fresh.append(words.pop_front())
	var new_ids: Array = []
	var new_cap := maxi(0, DAILY_NEW_LIMIT - new_used_today)
	for item in fresh:
		if new_ids.size() >= new_cap:
			break
		new_ids.append(item.id)

	var want_due := int(round(n * SHARE_DUE))
	var want_new := int(round(n * SHARE_NEW))
	var want_mis := n - want_due - want_new

	var out: Array = []
	_take(out, mistakes, want_mis)
	_take(out, due, want_due)
	_take(out, new_ids, want_new)
	# Fill shortfalls: due -> new -> mistakes -> early review.
	for group in [due, new_ids, mistakes, early]:
		_take(out, group, n - out.size())
	# Thin content (e.g. day one): repeat what we have.
	var base := out.duplicate()
	var i := 0
	while out.size() < n and base.size() > 0:
		out.append(base[i % base.size()])
		i += 1
	return out


## Sentences get harder as the learner progresses: tier 4 sentences are only
## introduced once enough tier 3 sentences sit in box 3 or higher.
const TIER4_AFTER_TIER3_KNOWN := 10


static func max_new_tier(items_in_order: Array, cards: Dictionary) -> int:
	var known := 0
	var total := 0
	for item in items_in_order:
		if str(item.get("kind", "")) != "phrase" or int(item.get("tier", 1)) != 3:
			continue
		total += 1
		if cards.has(item.id) and int(cards[item.id].get("box", 1)) >= 3:
			known += 1
	if total == 0 or known >= mini(TIER4_AFTER_TIER3_KNOWN, total):
		return 4
	return 3


static func _unit_rank(unit: int, start_unit: int) -> int:
	return unit - start_unit if unit >= start_unit else 100 + unit


static func _take(out: Array, src: Array, count: int) -> void:
	var taken := 0
	while taken < count and src.size() > 0:
		var id = src.pop_front()
		if out.has(id):
			continue
		out.append(id)
		taken += 1
