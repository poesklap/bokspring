extends RefCounted
## Difficulty profiles. Difficulty controls: starting unit, game speed,
## how similar wrong answers are, and direction (Afrikaans -> English first,
## English -> Afrikaans later). Bokspring uses 5 lanes (5 choices) at every
## level, at the player's request; "lanes" stays configurable per profile.

const BEGINNER := "beginner"
const ELEMENTARY := "elementary"
const INTERMEDIATE := "intermediate"
const ADVANCED := "advanced"
const LEVELS := [BEGINNER, ELEMENTARY, INTERMEDIATE, ADVANCED]

const PROFILES := {
	BEGINNER: {
		"label": "Beginner", "startUnit": 1, "maxUnlockedUnit": 1,
		"speed": 0.8, "lanes": 5, "similarity": 0.25,
		# en->af only once an item is well known
		"reverseFromBox": 4, "reverseChance": 0.3,
	},
	ELEMENTARY: {
		"label": "Elementary", "startUnit": 1, "maxUnlockedUnit": 2,
		"speed": 1.0, "lanes": 5, "similarity": 0.5,
		"reverseFromBox": 3, "reverseChance": 0.5,
	},
	INTERMEDIATE: {
		"label": "Intermediate", "startUnit": 2, "maxUnlockedUnit": 3,
		"speed": 1.15, "lanes": 5, "similarity": 0.75, "sentencesEarly": true,
		"reverseFromBox": 2, "reverseChance": 0.5,
	},
	ADVANCED: {
		"label": "Advanced", "startUnit": 3, "maxUnlockedUnit": 4,
		"speed": 1.3, "lanes": 5, "similarity": 0.95, "sentencesEarly": true,
		"reverseFromBox": 2, "reverseChance": 0.6,
	},
}


static func profile(level: String) -> Dictionary:
	return PROFILES.get(level, PROFILES[ELEMENTARY])


## Placement test tier (1-4) -> difficulty level.
static func level_for_tier(tier: int) -> String:
	return LEVELS[clampi(tier, 1, 4) - 1]
