extends RefCounted
## Builds one challenge dictionary for an item. Format (shared by all skins):
## { id, type, prompt, promptAudio, options, correctIndex, itemId,
##   timeLimitMs, pairAf, pairEn }

const Distractors = preload("res://src/engine/distractors.gd")

const TYPE_AF_EN := "translate_af_en"
const TYPE_EN_AF := "translate_en_af"
const TYPE_LISTEN := "listen_pick"

## Lower boxes (less familiar) get more time.
const BOX_TIME_FACTOR := [1.35, 1.15, 1.0, 0.9, 0.8]


## Fair timing: scales with prompt and option length and the learner's box.
static func time_limit_ms(prompt: String, options: Array, box: int, speed: float) -> int:
	var chars := 0
	for o in options:
		chars += str(o).length()
	var ms := 2200.0 + 70.0 * prompt.length() + 20.0 * chars
	ms *= BOX_TIME_FACTOR[clampi(box, 1, 5) - 1]
	ms /= maxf(speed, 0.1)
	return clampi(int(ms), 2000, 10000)


static func build(item: Dictionary, type: String, pool: Array, lanes: int,
		similarity: float, box: int, speed: float, rng: RandomNumberGenerator,
		challenge_id: String) -> Dictionary:
	var direction := Distractors.EN_AF if type == TYPE_EN_AF else Distractors.AF_EN
	var wrong := Distractors.pick(item, pool, lanes - 1, direction, similarity, rng)
	var options: Array = [Distractors.answer_text(item, direction)]
	for w in wrong:
		options.append(Distractors.answer_text(w, direction))
	var correct_text: String = options[0]
	Distractors.shuffle(options, rng)
	var prompt := Distractors.prompt_text(item, direction)
	if type == TYPE_LISTEN:
		prompt = ""
	return {
		"id": challenge_id,
		"type": type,
		"prompt": prompt,
		"promptAudio": str(item.get("af", "")),
		"options": options,
		"correctIndex": options.find(correct_text),
		"itemId": str(item.get("id", "")),
		"timeLimitMs": time_limit_ms(prompt if prompt != "" else str(item.get("af", "")), options, box, speed),
		"pairAf": str(item.get("af", "")),
		"pairEn": str(item.get("en", "")),
	}
