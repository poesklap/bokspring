extends RefCounted
const Loader = preload("res://src/content/content_loader.gd")
var t


func test_real_content_is_valid() -> void:
	var r := Loader.load_all()
	t.ok(r.ok, "content errors: %s" % str(r.errors.slice(0, 5)))
	t.ok(r.items.size() >= 140, "about 150 items: %d" % r.items.size())
	t.ok(r.placement.size() >= 12, "placement bank")


func test_bad_item_is_rejected() -> void:
	var e := Loader.validate_item({"id": "Hond!", "af": "hond", "en": "", "unit": 2,
		"category": "animal", "partOfSpeech": "noun", "kind": "word", "tier": 9}, 1)
	t.ok(e.size() >= 4, "id, empty en, unit mismatch, tier: %s" % str(e))
	var m := Loader.validate_item({"id": "w_x"}, 1)
	t.ok(m.size() > 0, "missing fields reported")


func test_bad_question_is_rejected() -> void:
	var e := Loader.validate_question({"id": "q", "tier": 1, "prompt": "x",
		"options": ["a", "a"], "correctIndex": 5})
	t.eq(e.size(), 2, "duplicate options + bad index")


func test_every_real_item_can_make_a_3_lane_challenge() -> void:
	var r := Loader.load_all()
	var e := LearningEngine.new({"items": r.items, "units": r.units},
		{"difficulty": "advanced"}, 3000, 11)
	var CG = preload("res://src/engine/challenge_gen.gd")
	var rng := RandomNumberGenerator.new()
	rng.seed = 2
	var thin: Array = []
	for it in r.items:
		var c: Dictionary = CG.build(it, CG.TYPE_AF_EN, r.items, 3, 0.9, 1, 1.0, rng, "x")
		if c.options.size() < 3:
			thin.append(it.id)
		t.eq(c.options[c.correctIndex], it.en, "correct option for " + it.id)
	t.eq(thin, [], "items without enough distractors")
