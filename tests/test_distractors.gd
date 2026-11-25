extends RefCounted
const D = preload("res://src/engine/distractors.gd")
const ChallengeGen = preload("res://src/engine/challenge_gen.gd")
var t


func _item(id: String, af: String, en: String, cat: String, kind := "word", pos := "noun") -> Dictionary:
	return {"id": id, "af": af, "en": en, "category": cat, "kind": kind, "partOfSpeech": pos, "unit": 1}


func _pool() -> Array:
	return [
		_item("w_hond", "hond", "dog", "animal"),
		_item("w_hand", "hand", "hand", "body"),
		_item("w_huis", "huis", "house", "home"),
		_item("w_kat", "kat", "cat", "animal"),
		_item("w_perd", "perd", "horse", "animal"),
		_item("w_brood", "brood", "bread", "food"),
		_item("w_kaas", "kaas", "cheese", "food"),
		_item("w_melk", "melk", "milk", "drink"),
		_item("w_rooi", "rooi", "red", "colour", "word", "adjective"),
		_item("w_blou", "blou", "blue", "colour", "word", "adjective"),
		_item("p_hoe", "Hoe gaan dit?", "How are you?", "greeting", "phrase", "phrase"),
	]


func _rng(s := 1) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = s
	return r


func test_levenshtein() -> void:
	t.eq(D.levenshtein("hond", "hand"), 1, "hond/hand")
	t.eq(D.levenshtein("", "abc"), 3, "empty")
	t.eq(D.levenshtein("kitten", "sitting"), 3, "classic")


func test_high_similarity_picks_close_spelling_and_category() -> void:
	var pool := _pool()
	var picked := D.pick(pool[0], pool, 2, D.AF_EN, 1.0, _rng())
	var ids := picked.map(func(i): return i.id)
	t.eq(picked.size(), 2, "two distractors")
	# hand is 1 edit from hond; kat/perd share the category
	t.ok(ids.has("w_hand"), "hand chosen for hond: %s" % str(ids))
	t.ok(not ids.has("w_hond"), "never the answer itself")


func test_never_mixes_words_and_phrases() -> void:
	var pool := _pool()
	for s in 20:
		var picked := D.pick(pool[0], pool, 3, D.AF_EN, 0.0, _rng(s))
		for p in picked:
			t.ok(p.kind == "word", "word only")
	var ph := D.pick(pool[10], pool, 3, D.AF_EN, 0.5, _rng())
	t.eq(ph.size(), 0, "no other phrases in pool")


func test_never_offers_a_second_correct_answer() -> void:
	var a := _item("w_more", "môre", "tomorrow", "time")
	a["altEn"] = ["morning"]
	var b := _item("w_oggend", "oggend", "morning", "time")
	var c := _item("w_gister", "gister", "yesterday", "time")
	var picked := D.pick(a, [a, b, c], 2, D.AF_EN, 1.0, _rng())
	var ids := picked.map(func(i): return i.id)
	t.ok(not ids.has("w_oggend"), "alt meaning excluded")
	t.ok(ids.has("w_gister"), "valid distractor kept")


func test_duplicate_answer_text_excluded() -> void:
	var a := _item("w_a", "baie dankie", "thanks", "courtesy")
	var b := _item("w_b", "dankie", "thanks", "courtesy")
	var picked := D.pick(a, [a, b], 1, D.AF_EN, 1.0, _rng())
	t.eq(picked.size(), 0, "same English excluded")


func test_low_similarity_is_wider_but_still_valid() -> void:
	var pool := _pool()
	var seen := {}
	for s in 40:
		for p in D.pick(pool[0], pool, 2, D.AF_EN, 0.0, _rng(s)):
			seen[p.id] = true
			t.ok(p.id != "w_hond", "not the answer")
	t.ok(seen.size() >= 4, "low similarity varies distractors: %d" % seen.size())


func test_challenge_has_correct_index_and_unique_options() -> void:
	var pool := _pool()
	for s in 20:
		var c := ChallengeGen.build(pool[0], ChallengeGen.TYPE_AF_EN, pool, 3, 0.5, 1, 1.0, _rng(s), "c_1")
		t.eq(c.options.size(), 3, "3 lanes")
		t.eq(c.options[c.correctIndex], "dog", "correct option")
		t.eq(c.prompt, "hond", "prompt is Afrikaans")
		var uniq := {}
		for o in c.options:
			uniq[o] = true
		t.eq(uniq.size(), 3, "options unique")
	var r := ChallengeGen.build(pool[0], ChallengeGen.TYPE_EN_AF, pool, 4, 0.5, 1, 1.0, _rng(), "c_2")
	t.eq(r.prompt, "dog", "reverse prompt in English")
	t.eq(r.options[r.correctIndex], "hond", "reverse answer in Afrikaans")


func test_time_limit_scales_with_length_and_box() -> void:
	var short := ChallengeGen.time_limit_ms("kat", ["cat", "dog"], 1, 1.0)
	var long := ChallengeGen.time_limit_ms("Mag ek water kry, asseblief?", ["May I have water, please?", "Where is the water?"], 1, 1.0)
	t.ok(long > short, "longer prompt -> more time")
	var b1 := ChallengeGen.time_limit_ms("hond", ["dog", "hand"], 1, 1.0)
	var b5 := ChallengeGen.time_limit_ms("hond", ["dog", "hand"], 5, 1.0)
	t.ok(b1 > b5, "box 1 gets more time than box 5")
	var fast := ChallengeGen.time_limit_ms("hond", ["dog", "hand"], 3, 1.3)
	var slow := ChallengeGen.time_limit_ms("hond", ["dog", "hand"], 3, 0.8)
	t.ok(slow > fast, "slower difficulty -> more time")
	t.ok(short >= 2000 and long <= 10000, "clamped")


func test_shared_meaning_excluded_in_reverse_direction_too() -> void:
	var a := _item("w_jammer", "jammer", "sorry", "courtesy")
	var b := _item("w_ekskuus", "ekskuus", "excuse me", "courtesy")
	b["altEn"] = ["sorry"]
	var c := _item("w_dankie", "dankie", "thank you", "courtesy")
	for dir in [D.AF_EN, D.EN_AF]:
		var picked := D.pick(a, [a, b, c], 2, dir, 1.0, _rng())
		t.ok(not picked.map(func(i): return i.id).has("w_ekskuus"), "ekskuus never a wrong answer for jammer (%s)" % dir)
