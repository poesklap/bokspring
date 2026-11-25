extends RefCounted
const RunState = preload("res://src/skins/bokspring/run_state.gd")
var t


func test_lives_carry_over_between_levels() -> void:
	var s := RunState.create()
	RunState.lose_life(s)
	RunState.lose_life(s)
	RunState.complete_level(s, 80.0)
	t.eq(int(s.level), 2, "next level")
	t.eq(int(s.lives), 3, "lives carried over, not refilled")


func test_game_over_resets_level_lives_coins_skips_but_keeps_cosmetics() -> void:
	var s := RunState.create()
	s.coins = 40
	s.skips = 2
	s.level = 6
	s.cosmetics = ["hat_red"]
	s.arenas = ["veld", "beach"]
	s.bestByLevel = {"1": 70.0}
	var over := false
	for i in 5:
		over = RunState.lose_life(s)
	t.ok(over, "5th crash is game over")
	RunState.game_over_reset(s)
	t.eq(int(s.level), 1, "level 1")
	t.eq(int(s.lives), 5, "5 lives")
	t.eq(int(s.coins), 0, "coins reset")
	t.eq(int(s.skips), 0, "skips lost")
	t.eq(s.cosmetics, ["hat_red"], "cosmetics kept")
	t.eq(s.arenas, ["veld", "beach"], "arenas kept")
	t.eq(float(s.bestByLevel["1"]), 70.0, "bests kept")


func test_coins_with_streak_bonus() -> void:
	var s := RunState.create()
	t.eq(RunState.add_coins_for_correct(s, 1), 1, "1 coin")
	t.eq(RunState.add_coins_for_correct(s, 5), 6, "bonus at 5")
	t.eq(RunState.add_coins_for_correct(s, 10), 11, "bonus at 10")
	t.eq(int(s.coins), 18, "total")


func test_personal_best() -> void:
	var s := RunState.create()
	t.ok(RunState.complete_level(s, 90.0), "first is a record")
	s.level = 1
	t.ok(not RunState.complete_level(s, 95.0), "slower is not")
	s.level = 1
	t.ok(RunState.complete_level(s, 85.0), "faster is")


func test_normalise_never_starts_with_zero_lives() -> void:
	var s := RunState.normalise({"lives": 0, "level": 4})
	t.eq(int(s.lives), 5, "refilled")
