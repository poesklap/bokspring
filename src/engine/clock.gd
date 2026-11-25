extends RefCounted
## Day arithmetic. The engine never reads the system clock itself: callers
## pass in a day index, which keeps everything deterministic and testable.


## Whole local days since 1970-01-01.
static func day_index(unix_seconds: float, tz_offset_seconds: int) -> int:
	return floori((unix_seconds + tz_offset_seconds) / 86400.0)


## Day index for "now" on this device.
static func today() -> int:
	var tz: Dictionary = Time.get_time_zone_from_system()
	return day_index(Time.get_unix_time_from_system(), int(tz.get("bias", 0)) * 60)


## Week number with weeks starting on Monday (1970-01-01 was a Thursday).
static func week_index(day: int) -> int:
	return floori((day + 3) / 7.0)
