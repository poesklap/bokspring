extends RefCounted
## Loads and validates the decks in res://content/*.json.
## Used at runtime and by tools/validate_content.gd at build time
## (a bad entry fails the build).

const DIR := "res://content/"
const REQUIRED := ["id", "af", "en", "unit", "category", "partOfSpeech", "kind", "tier"]
const KINDS := ["word", "phrase"]
const POS := ["noun", "verb", "adjective", "adverb", "interjection", "phrase", "number",
	"pronoun", "preposition", "conjunction", "determiner", "numeral", "article"]
const MAX_ANSWER_LEN := 28       # words: they appear on answer buttons
const MAX_SENTENCE_LEN := 90     # phrases / sentences (kept short on purpose)
const MAX_EXAMPLE_LEN := 60


static func _read_json(path: String, errors: Array):
	if not FileAccess.file_exists(path):
		errors.append("%s: file missing" % path)
		return null
	var text := FileAccess.get_file_as_string(path)
	var json := JSON.new()
	if json.parse(text) != OK:
		errors.append("%s: invalid JSON at line %d: %s" % [path, json.get_error_line(), json.get_error_message()])
		return null
	return json.data


## Returns {ok, errors: Array[String], units, items, placement, tips}.
static func load_all(dir: String = DIR) -> Dictionary:
	var errors: Array = []
	var items: Array = []
	var units: Array = []
	var meta = _read_json(dir + "units.json", errors)
	if meta is Dictionary and meta.get("units") is Array:
		units = meta.units
	elif meta != null:
		errors.append("units.json: needs a 'units' array")

	var ids := {}
	var en_seen := {}
	var af_seen := {}
	for u in units:
		for k in ["id", "titleAf", "titleEn", "file", "xpToUnlock"]:
			if not u.has(k):
				errors.append("units.json: unit missing '%s'" % k)
		if not u.has("file"):
			continue
		var deck = _read_json(dir + str(u.file), errors)
		if not (deck is Dictionary and deck.get("items") is Array):
			if deck != null:
				errors.append("%s: needs an 'items' array" % u.file)
			continue
		for it in deck.items:
			var where := "%s: %s" % [u.file, str(it.get("id", "?")) if it is Dictionary else "?"]
			if not it is Dictionary:
				errors.append(where + " is not an object")
				continue
			var item_errors := validate_item(it, int(u.id))
			for e in item_errors:
				errors.append(where + ": " + e)
			if not item_errors.is_empty():
				continue
			if ids.has(it.id):
				errors.append(where + ": duplicate id")
			ids[it.id] = true
			var en := str(it.en).to_lower()
			var af := str(it.af).to_lower()
			if en_seen.has(en):
				errors.append(where + ": English '%s' also used by %s" % [it.en, en_seen[en]])
			if af_seen.has(af):
				errors.append(where + ": Afrikaans '%s' also used by %s" % [it.af, af_seen[af]])
			en_seen[en] = it.id
			af_seen[af] = it.id
			it.unit = int(it.unit)
			it.tier = int(it.tier)
			items.append(it)

	# altEn may name another item's answer: the engine then never offers the
	# two as each other's wrong answer (see distractors.gd conflicts()).
	for it in items:
		for alt in it.get("altEn", []):
			if str(alt).strip_edges() == "":
				errors.append("%s: empty altEn entry" % it.id)

	var placement: Array = []
	var pl = _read_json(dir + "placement.json", errors)
	if pl is Dictionary and pl.get("questions") is Array:
		placement = pl.questions
		for q in placement:
			errors.append_array(validate_question(q))
	var tips: Array = []
	var tp = _read_json(dir + "tips.json", errors)
	if tp is Dictionary and tp.get("tips") is Array:
		tips = tp.tips
		for tip in tips:
			for k in ["id", "titleEn", "bodyEn", "showAfterLevel"]:
				if not tip.has(k):
					errors.append("tips.json: %s missing '%s'" % [tip.get("id", "?"), k])
	if items.is_empty():
		errors.append("no items loaded")
	return {"ok": errors.is_empty(), "errors": errors, "units": units, "items": items,
		"placement": placement, "tips": tips}


static func _max_len(it: Dictionary) -> int:
	return MAX_SENTENCE_LEN if str(it.get("kind", "")) == "phrase" else MAX_ANSWER_LEN


static func validate_item(it: Dictionary, unit_id: int) -> Array:
	var e: Array = []
	for k in REQUIRED:
		if not it.has(k):
			e.append("missing '%s'" % k)
	if not e.is_empty():
		return e
	var id_re := RegEx.create_from_string("^[wp]_[a-z0-9_]+$")
	if id_re.search(str(it.id)) == null:
		e.append("bad id (use w_/p_ + lowercase ascii)")
	for k in ["af", "en"]:
		var v := str(it[k]).strip_edges()
		if v == "":
			e.append("empty '%s'" % k)
		elif v.length() > _max_len(it):
			e.append("'%s' longer than %d chars" % [k, _max_len(it)])
	# Hand-written near-miss wrong answers (sentences): exactly 4, none equal to the answer.
	for pair in [["wrongEn", "en"], ["wrongAf", "af"]]:
		if not it.has(pair[0]):
			continue
		var w = it[pair[0]]
		if not w is Array or w.size() != 4:
			e.append("'%s' must be an array of 4" % pair[0])
			continue
		var seen := {str(it[pair[1]]).to_lower(): true}
		for x in w:
			var t := str(x).strip_edges()
			if t == "" or t.length() > _max_len(it) or seen.has(t.to_lower()):
				e.append("'%s' has an empty, too long or duplicate entry: %s" % [pair[0], t])
			seen[t.to_lower()] = true
	for k in ["exampleAf", "exampleEn"]:
		if it.has(k) and str(it[k]).length() > MAX_EXAMPLE_LEN:
			e.append("'%s' too long" % k)
	if int(it.unit) != unit_id:
		e.append("unit %s does not match units.json (%d)" % [str(it.unit), unit_id])
	if not KINDS.has(it.kind):
		e.append("kind must be word or phrase")
	if not POS.has(it.partOfSpeech):
		e.append("unknown partOfSpeech '%s'" % it.partOfSpeech)
	if not (int(it.tier) >= 1 and int(it.tier) <= 4):
		e.append("tier must be 1-4")
	if it.has("altEn") and not it.altEn is Array:
		e.append("altEn must be an array")
	return e


static func validate_question(q) -> Array:
	var e: Array = []
	var id := str(q.get("id", "?")) if q is Dictionary else "?"
	if not q is Dictionary:
		return ["placement: entry is not an object"]
	for k in ["id", "tier", "prompt", "options", "correctIndex"]:
		if not q.has(k):
			e.append("placement %s: missing '%s'" % [id, k])
	if not e.is_empty():
		return e
	if not q.options is Array or q.options.size() < 2:
		e.append("placement %s: needs 2+ options" % id)
	else:
		var uniq := {}
		for o in q.options:
			uniq[str(o).to_lower()] = true
		if uniq.size() != q.options.size():
			e.append("placement %s: duplicate options" % id)
		if int(q.correctIndex) < 0 or int(q.correctIndex) >= q.options.size():
			e.append("placement %s: correctIndex out of range" % id)
	if int(q.tier) < 1 or int(q.tier) > 4:
		e.append("placement %s: tier must be 1-4" % id)
	return e
