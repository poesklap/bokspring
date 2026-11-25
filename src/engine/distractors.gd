extends RefCounted
## Picks wrong answers that make guesses costly: same kind (word/phrase),
## preferably the same category, part of speech and similar spelling
## (hond / hand / huis). Never picks an option that would also be correct.

const AF_EN := "af_en"
const EN_AF := "en_af"


static func answer_text(item: Dictionary, direction: String) -> String:
	return str(item.get("en", "")) if direction == AF_EN else str(item.get("af", ""))


static func prompt_text(item: Dictionary, direction: String) -> String:
	return str(item.get("af", "")) if direction == AF_EN else str(item.get("en", ""))


static func levenshtein(a: String, b: String) -> int:
	var n := b.length()
	if a.length() == 0:
		return n
	if n == 0:
		return a.length()
	var prev: Array[int] = []
	prev.resize(n + 1)
	for j in n + 1:
		prev[j] = j
	for i in range(1, a.length() + 1):
		var cur: Array[int] = []
		cur.resize(n + 1)
		cur[0] = i
		for j in range(1, n + 1):
			var cost := 0 if a[i - 1] == b[j - 1] else 1
			cur[j] = mini(mini(cur[j - 1] + 1, prev[j] + 1), prev[j - 1] + cost)
		prev = cur
	return prev[n]


## 1.0 = identical, 0.0 = nothing in common.
static func spelling_similarity(a: String, b: String) -> float:
	a = a.to_lower()
	b = b.to_lower()
	var m := maxi(a.length(), b.length())
	if m == 0:
		return 1.0
	return 1.0 - float(levenshtein(a, b)) / float(m)


static func _lower_set(values) -> Dictionary:
	var d := {}
	if values is Array:
		for v in values:
			d[str(v).to_lower()] = true
	return d


## True when `cand` must not be offered as a wrong answer for `target`.
static func conflicts(target: Dictionary, cand: Dictionary, direction: String) -> bool:
	if cand.get("id") == target.get("id"):
		return true
	if answer_text(cand, direction).to_lower() == answer_text(target, direction).to_lower():
		return true
	if prompt_text(cand, direction).to_lower() == prompt_text(target, direction).to_lower():
		return true
	# Alternative meanings would make two options correct.
	if direction == AF_EN:
		if _lower_set(target.get("altEn", [])).has(str(cand.get("en", "")).to_lower()):
			return true
		if _lower_set(cand.get("altEn", [])).has(str(target.get("en", "")).to_lower()):
			return true
	return false


static func score(target: Dictionary, cand: Dictionary) -> float:
	var s := 0.0
	if cand.get("category") == target.get("category"):
		s += 2.0
	if cand.get("partOfSpeech") == target.get("partOfSpeech"):
		s += 1.0
	var sim := maxf(
		spelling_similarity(str(cand.get("af", "")), str(target.get("af", ""))),
		spelling_similarity(str(cand.get("en", "")), str(target.get("en", ""))))
	s += 3.0 * sim
	return s


## Returns up to `count` distractor items for `target`.
## similarity_level 1.0 = always the closest candidates; 0.0 = a wide random pick.
static func pick(target: Dictionary, pool: Array, count: int, direction: String,
		similarity_level: float, rng: RandomNumberGenerator) -> Array:
	if count <= 0:
		return []
	var target_kind := str(target.get("kind", "word"))
	var scored: Array = []
	for cand in pool:
		if str(cand.get("kind", "word")) != target_kind:
			continue
		if conflicts(target, cand, direction):
			continue
		scored.append({"item": cand, "score": score(target, cand)})
	scored.sort_custom(func(a, b):
		if is_equal_approx(a.score, b.score):
			return str(a.item.id) < str(b.item.id)
		return a.score > b.score)
	var window := count + int(round((1.0 - clampf(similarity_level, 0.0, 1.0)) * count * 4.0))
	window = mini(window, scored.size())
	var top: Array = scored.slice(0, window)
	shuffle(top, rng)
	var out: Array = []
	var seen := {answer_text(target, direction).to_lower(): true}
	for entry in top:
		var t := answer_text(entry.item, direction).to_lower()
		if seen.has(t):
			continue
		seen[t] = true
		out.append(entry.item)
		if out.size() >= count:
			break
	return out


## Deterministic Fisher-Yates shuffle using the given RNG.
static func shuffle(arr: Array, rng: RandomNumberGenerator) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp
