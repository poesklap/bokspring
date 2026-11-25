extends RefCounted
## Bokspring's own game state (not learning progress): level, lives, coins,
## skips, personal bests, cosmetics and arenas. Saved separately from progress.

const START_LIVES := 5
const COIN_PER_CORRECT := 1
const COIN_BONUS := {5: 5, 10: 10}   # combo reached -> bonus coins


static func create() -> Dictionary:
	return {
		"level": 1, "lives": START_LIVES, "coins": 0, "skips": 0,
		"highestLevel": 1, "bestByLevel": {},
		"cosmetics": [], "arenas": ["veld"], "arena": "veld",
		"gamesOver": 0,
	}


static func normalise(s: Dictionary) -> Dictionary:
	var base := create()
	for k in base:
		if not s.has(k) or typeof(s[k]) != typeof(base[k]):
			s[k] = base[k]
	s.lives = clampi(int(s.lives), 0, 99)
	if int(s.lives) <= 0:
		s.lives = START_LIVES
	return s


## Coins for a correct answer at this combo count. Returns coins added.
static func add_coins_for_correct(s: Dictionary, combo: int) -> int:
	var c: int = COIN_PER_CORRECT + int(COIN_BONUS.get(combo, 0))
	s.coins = int(s.coins) + c
	return c


## Returns true when that was the last life (game over).
static func lose_life(s: Dictionary) -> bool:
	s.lives = maxi(0, int(s.lives) - 1)
	return int(s.lives) == 0


## Level finished. Returns true if it's a new personal best (fewest seconds).
static func complete_level(s: Dictionary, seconds: float) -> bool:
	var key := str(int(s.level))
	var prev = s.bestByLevel.get(key)
	var record: bool = prev == null or seconds < float(prev)
	if record:
		s.bestByLevel[key] = snappedf(seconds, 0.1)
	s.level = int(s.level) + 1
	s.highestLevel = maxi(int(s.highestLevel), int(s.level))
	return record


## Game over: back to level 1 with 5 lives; coins and unused skips are lost.
## Cosmetics, arenas and personal bests are kept (word mastery lives elsewhere).
static func game_over_reset(s: Dictionary) -> void:
	s.level = 1
	s.lives = START_LIVES
	s.coins = 0
	s.skips = 0
	s.gamesOver = int(s.gamesOver) + 1
