extends Control
## Start menu: Play, daily goal ring, streak, XP, next unlock, settings.
## Shop, word garden and stats arrive in M2/M3 (shown as "coming soon").

const U = preload("res://src/ui/ui_util.gd")
const Progress = preload("res://src/engine/progress.gd")

signal play
signal open_settings

var ring: Control


func _ready() -> void:
	var box := U.page(self)
	var e: LearningEngine = Game.engine
	var top := HBoxContainer.new()
	box.add_child(top)
	var streak := e.streak()
	top.add_child(U.icon("res://assets/ui/flame.svg", 36))
	U.label(top, "%d day streak" % streak)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(sp)
	top.add_child(U.icon("res://assets/ui/xp_star.svg", 32))
	U.label(top, "%d XP" % int(e.progress.xp))

	U.label(box, "Bokspring", "TitleLabel", true)
	var hero := U.icon("res://assets/springbok/hero.svg", 260)
	hero.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(hero)

	# Daily goal ring: 3 rounds or 50 XP.
	ring = GoalRing.new()
	ring.progress = e.goal_progress()
	ring.custom_minimum_size = Vector2(120, 120)
	ring.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(ring)
	var d: Dictionary = e.progress.daily
	var goal_text := "Today's goal done! 🎉" if d.goalMet else \
		"Today: %d/%d rounds or %d/%d XP" % [int(d.rounds), Progress.GOAL_ROUNDS, int(d.xp), Progress.GOAL_XP]
	U.label(box, goal_text, "MutedLabel", true)

	var run: Dictionary = Game.run
	var play_text := "Speel  (play)" if int(run.level) == 1 and int(run.lives) == 5 else \
		"Speel  · vlak %d  · ♥ %d" % [int(run.level), int(run.lives)]
	U.button(box, play_text, func(): play.emit())

	var unlock := e.next_unlock()
	if not unlock.is_empty():
		U.label(box, "Next unit: %s, in %d XP" % [unlock.unit.titleEn, int(unlock.xpNeeded)], "MutedLabel", true)
	var boxes := Progress.count_by_box(e.progress)
	U.label(box, "Words met: %d  ·  mastered: %d" % [e.progress.cards.size(), boxes[4]], "MutedLabel", true)
	U.spacer(box)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	for t in ["Winkel", "Tuin"]:
		var b := Button.new()
		b.text = t
		b.tooltip_text = "Coming soon"
		b.disabled = true
		b.clip_text = true
		b.theme_type_variation = &"GhostButton"
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(b)
	var s := U.button(row, "Instellings", func(): open_settings.emit(), "SecondaryButton")
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.size_flags_stretch_ratio = 1.6
	s.clip_text = true
	U.label(box, "Shop and word garden open in the next update.", "MutedLabel", true)


class GoalRing extends Control:
	var progress := 0.0

	func _draw() -> void:
		var c := size / 2
		var r := minf(size.x, size.y) / 2 - 10
		draw_arc(c, r, 0, TAU, 64, Color(0, 0, 0, 0.1), 14, true)
		if progress > 0.0:
			draw_arc(c, r, -PI / 2, -PI / 2 + TAU * progress, 64, Style.PRIMARY, 14, true)
		var f := get_theme_default_font()
		var txt := "%d%%" % int(progress * 100)
		var w := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 28).x
		draw_string(f, c + Vector2(-w / 2, 10), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Style.TEXT)
