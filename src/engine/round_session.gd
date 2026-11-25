extends RefCounted
## One round (a Bokspring "level"): N slots that must each be answered
## correctly. A missed slot comes back later in the same round.
## Also tracks the combo streak and multiplier (x2 at 5, x3 at 10).

const REQUEUE_GAP := 2   # a missed item returns after this many other challenges

var slots: Array = []        # [{itemId, done}]
var queue: Array = []        # slot indices still to ask, in order
var current_slot := -1
var combo := 0
var best_combo := 0
var answered := 0
var correct_count := 0
var wrong_count := 0
var missed_items: Array = [] # item ids answered wrong at least once (unique)


func _init(item_ids: Array) -> void:
	for id in item_ids:
		queue.append(slots.size())
		slots.append({"itemId": str(id), "done": false})


func size() -> int:
	return slots.size()


func done_count() -> int:
	var n := 0
	for s in slots:
		if s.done:
			n += 1
	return n


func is_complete() -> bool:
	return slots.size() > 0 and done_count() == slots.size()


## Next item id to ask, or "" when the round is complete.
func next_item() -> String:
	if queue.is_empty():
		current_slot = -1
		return ""
	current_slot = queue.pop_front()
	return slots[current_slot].itemId


func current_item() -> String:
	return "" if current_slot < 0 else slots[current_slot].itemId


static func multiplier_for(combo_count: int) -> int:
	if combo_count >= 10:
		return 3
	if combo_count >= 5:
		return 2
	return 1


func multiplier() -> int:
	return multiplier_for(combo)


## Records the answer for the current slot.
func record(correct: bool) -> void:
	if current_slot < 0:
		return
	answered += 1
	if correct:
		correct_count += 1
		combo += 1
		best_combo = maxi(best_combo, combo)
		slots[current_slot].done = true
	else:
		wrong_count += 1
		combo = 0
		var id: String = slots[current_slot].itemId
		if not missed_items.has(id):
			missed_items.append(id)
		queue.insert(mini(REQUEUE_GAP, queue.size()), current_slot)
	current_slot = -1


## Removes the current slot from the round without counting it (skip button, M2).
func skip_current() -> void:
	if current_slot >= 0:
		slots[current_slot].done = true
		current_slot = -1
