extends RefCounted
## Adaptive placement test that starts HARD and falls back.
## It begins at the top tier (Grade 11-12 Home Language sentences). At each
## tier it asks up to QUESTIONS_PER_TIER questions: PASS_RIGHT correct places
## the learner at that tier; FAIL_WRONG wrong drops one tier. Failing tier 1
## still places at Beginner.
##   tier 4 -> Advanced      (Grade 11-12 HL sentences)
##   tier 3 -> Intermediate  (Grade 8-9 HL sentences)
##   tier 2 -> Elementary    (everyday words and short phrases)
##   tier 1 -> Beginner      (basics)

const Distractors = preload("res://src/engine/distractors.gd")
const Difficulty = preload("res://src/engine/difficulty.gd")

const MAX_TIER := 4
const QUESTIONS_PER_TIER := 4
const PASS_RIGHT := 3
const FAIL_WRONG := 2
const LENGTH := MAX_TIER * QUESTIONS_PER_TIER   # worst case

var bank := {1: [], 2: [], 3: [], 4: []}
var rng: RandomNumberGenerator
var tier := MAX_TIER
var asked := 0
var right_here := 0
var wrong_here := 0
var placed_tier := 0      # 0 = still testing
var history: Array = []   # [tier, correct]
var current: Dictionary = {}


## questions: [{id, tier, prompt, options, correctIndex}] (see build_bank()).
func _init(questions: Array, random: RandomNumberGenerator) -> void:
	rng = random
	for q in questions:
		var t := clampi(int(q.get("tier", 1)), 1, MAX_TIER)
		bank[t].append(q)
	for t in bank:
		Distractors.shuffle(bank[t], rng)
	# Start at the hardest tier that actually has questions.
	while tier > 1 and bank[tier].is_empty():
		tier -= 1


## Placement bank: basic questions (placement.json) for tiers 1-2, and the
## game's own sentences for tiers 3-4, with their near-miss wrong answers.
static func build_bank(placement_questions: Array, items: Array) -> Array:
	var out: Array = []
	for q in placement_questions:
		if int(q.get("tier", 1)) <= 2:
			out.append(q)
	for it in items:
		if str(it.get("kind", "")) != "phrase" or int(it.get("tier", 1)) < 3:
			continue
		var wrong: Array = it.get("wrongEn", [])
		if wrong.size() < 3:
			continue
		out.append({"id": "pl_" + str(it.id), "tier": int(it.tier), "prompt": str(it.af),
			"options": [str(it.en), str(wrong[0]), str(wrong[1]), str(wrong[2])], "correctIndex": 0})
	return out


func is_done() -> bool:
	return placed_tier > 0


## Returns a challenge-shaped dictionary, or {} when the test is over.
func next_question() -> Dictionary:
	if is_done():
		return {}
	if bank[tier].is_empty():
		# Ran out at this tier without deciding: settle on the evidence.
		_place(tier if right_here >= wrong_here and right_here > 0 else maxi(1, tier - 1))
		return {}
	var q: Dictionary = bank[tier].pop_front()
	var options: Array = q.options.duplicate()
	var correct_text: String = options[int(q.correctIndex)]
	Distractors.shuffle(options, rng)
	current = {
		"id": str(q.id), "type": "translate_af_en", "prompt": str(q.prompt),
		"promptAudio": str(q.prompt), "options": options,
		"correctIndex": options.find(correct_text), "itemId": str(q.id), "tier": tier,
	}
	return current


func answer(correct: bool) -> void:
	if current.is_empty() or is_done():
		return
	asked += 1
	history.append([tier, correct])
	current = {}
	if correct:
		right_here += 1
	else:
		wrong_here += 1
	if right_here >= PASS_RIGHT:
		_place(tier)
	elif wrong_here >= FAIL_WRONG or right_here + wrong_here >= QUESTIONS_PER_TIER:
		if tier == 1:
			_place(1)
		else:
			tier -= 1
			right_here = 0
			wrong_here = 0


func _place(t: int) -> void:
	placed_tier = clampi(t, 1, MAX_TIER)


func result_tier() -> int:
	return placed_tier if placed_tier > 0 else 1


func result_level() -> String:
	return Difficulty.level_for_tier(result_tier())
