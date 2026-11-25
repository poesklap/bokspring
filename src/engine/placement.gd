extends RefCounted
## Adaptive placement test: about 12 questions. Starts with basic words and
## steps up a tier after 2 correct in a row; steps down after 2 wrong at a tier.
## Result: the highest tier answered with >= 60% accuracy (min 2 asked),
## mapped to Beginner / Elementary / Intermediate / Advanced.

const Distractors = preload("res://src/engine/distractors.gd")
const Difficulty = preload("res://src/engine/difficulty.gd")

const LENGTH := 12
const MAX_TIER := 4

var bank := {1: [], 2: [], 3: [], 4: []}
var rng: RandomNumberGenerator
var tier := 1
var asked := 0
var run_right := 0
var wrong_at_tier := 0
var per_tier := {1: [0, 0], 2: [0, 0], 3: [0, 0], 4: [0, 0]}  # [correct, asked]
var current: Dictionary = {}


func _init(questions: Array, random: RandomNumberGenerator) -> void:
	rng = random
	for q in questions:
		var t := clampi(int(q.get("tier", 1)), 1, MAX_TIER)
		bank[t].append(q)
	for t in bank:
		Distractors.shuffle(bank[t], rng)


func is_done() -> bool:
	return asked >= LENGTH or _no_questions_left()


func _no_questions_left() -> bool:
	for t in bank:
		if not bank[t].is_empty():
			return false
	return true


## Returns a challenge-shaped dictionary, or {} when the test is over.
func next_question() -> Dictionary:
	if is_done():
		return {}
	var t := tier
	# If this tier has run out, use the nearest tier that still has questions.
	var order := [t, t - 1, t + 1, t - 2, t + 2, t - 3, t + 3]
	for cand in order:
		if bank.has(cand) and not bank[cand].is_empty():
			t = cand
			break
	var q: Dictionary = bank[t].pop_front()
	var options: Array = q.options.duplicate()
	var correct_text: String = options[int(q.correctIndex)]
	Distractors.shuffle(options, rng)
	current = {
		"id": str(q.id), "type": "translate_af_en", "prompt": str(q.prompt),
		"promptAudio": str(q.prompt), "options": options,
		"correctIndex": options.find(correct_text), "itemId": str(q.id), "tier": t,
	}
	return current


func answer(correct: bool) -> void:
	if current.is_empty():
		return
	var t := int(current.tier)
	asked += 1
	per_tier[t][1] += 1
	if correct:
		per_tier[t][0] += 1
		run_right += 1
		wrong_at_tier = 0
		if run_right >= 2 and tier < MAX_TIER:
			tier += 1
			run_right = 0
	else:
		run_right = 0
		wrong_at_tier += 1
		if wrong_at_tier >= 2 and tier > 1:
			tier -= 1
			wrong_at_tier = 0
	current = {}


func result_tier() -> int:
	var best := 1
	for t in range(1, MAX_TIER + 1):
		var c: int = per_tier[t][0]
		var a: int = per_tier[t][1]
		if a >= 2 and float(c) / a >= 0.6:
			best = t
		elif a == 1 and c == 1 and t > best and t == MAX_TIER:
			best = t  # reached the top and got it right
	# Failing the basics means Beginner regardless.
	if per_tier[1][1] >= 2 and float(per_tier[1][0]) / per_tier[1][1] < 0.6:
		return 1
	return best


func result_level() -> String:
	return Difficulty.level_for_tier(result_tier())
