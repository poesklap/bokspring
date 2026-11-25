class_name Style
extends RefCounted
## Bokspring UI look, defined in code. See assets/STYLE_GUIDE.md.
## Design width is 540 px (project viewport), so sizes below are in that space.

# --- Palette -----------------------------------------------------------------
const BG := Color("#FBEFD9")            # warm cream screen background
const PRIMARY := Color("#E0662B")       # sunset orange: main buttons
const PRIMARY_DARK := Color("#A8441A")  # pressed / borders / shadows
const ACCENT := Color("#3D8FD0")        # veld-sky blue: secondary buttons, links
const TEXT := Color("#2B1D14")          # near-black brown
const TEXT_MUTED := Color("#7A6450")
const TEXT_ON_PRIMARY := Color("#FFFFFF")
const PANEL := Color("#FFF8EC")
const PANEL_BORDER := Color("#E8CFA4")
const GOOD := Color("#1B6FB0")          # correct (blue, not green: colour-blind safe)
const BAD := Color("#D9480F")           # wrong / crash (vermilion)
const GOLD := Color("#F5C542")          # coins, XP, stars
const INK := Color("#3A2416")           # art outline colour
const SHADE := Color(0, 0, 0, 0.35)     # dim behind modal panels

# --- Lanes -------------------------------------------------------------------
# Tints for lane highlights / sign borders. Normal set is soft and friendly.
const LANE_COLORS := [
	Color("#F2A541"),  # amber
	Color("#4FA3E0"),  # sky blue
	Color("#B48FD8"),  # lilac
	Color("#6CC6A6"),  # mint
]
# Colour-blind set (Okabe-Ito): neighbours alternate light/dark and blue/orange,
# so they stay distinct for protan, deutan and tritan vision. Pair with patterns.
const LANE_COLORS_CB := [
	Color("#E69F00"),  # orange, mid-light
	Color("#0072B2"),  # deep blue, dark
	Color("#F0E442"),  # yellow, very light
	Color("#56B4E9"),  # sky blue, light
]
const LANE_PATTERN_NAMES := ["dots", "stripes", "plain", "checks"]

# --- Type & sizes ------------------------------------------------------------
const FONT_SMALL := 20
const FONT_BASE := 26
const FONT_LARGE := 32
const FONT_TITLE := 44
const FONT_HUGE := 64      # big prompt / score pop
const TAP_MIN := 64        # minimum tap target height (px at 540 width)
const RADIUS := 18
const GAP := 16


static func _box(bg: Color, border: Color = Color.TRANSPARENT, border_w: int = 0,
		radius: int = RADIUS, pad_h: int = 24, pad_v: int = 12, shadow: int = 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	sb.corner_detail = 8
	sb.anti_aliasing = true
	if border_w > 0:
		sb.border_color = border
		sb.set_border_width_all(border_w)
	if shadow > 0:
		# solid offset "lip" under the button: flat cartoon depth
		sb.border_color = border
		sb.border_width_bottom = shadow
	sb.content_margin_left = pad_h
	sb.content_margin_right = pad_h
	sb.content_margin_top = pad_v
	sb.content_margin_bottom = pad_v
	return sb


static func _disc(size: int, fill: Color, ring: Color, ring_w: float) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c := (size - 1) / 2.0
	var r := size / 2.0 - 1.0
	for y in size:
		for x in size:
			var d := Vector2(x - c, y - c).length()
			var col := Color.TRANSPARENT
			if d <= r:
				col = ring if d > r - ring_w else fill
				col.a *= clampf(r - d + 0.5, 0.0, 1.0)  # soft edge
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)


static func _switch(on: bool) -> ImageTexture:
	var w := 72
	var h := 40
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var track := GOOD if on else Color("#BFAE98")
	var r := h / 2.0
	var knob_x := w - r if on else r
	for y in h:
		for x in w:
			var p := Vector2(x + 0.5, y + 0.5)
			var cx := clampf(p.x, r, w - r)
			var d := p.distance_to(Vector2(cx, r))
			var col := Color.TRANSPARENT
			if d <= r:
				col = track
				col.a = clampf(r - d + 0.5, 0.0, 1.0)
			var dk := p.distance_to(Vector2(knob_x, r))
			if dk <= r - 4:
				col = Color.WHITE
				col.a = clampf(r - 4 - dk + 0.5, 0.0, 1.0) if dk > r - 5 else 1.0
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)


static func make_theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = FONT_BASE

	# Label
	t.set_color("font_color", "Label", TEXT)
	t.set_font_size("font_size", "Label", FONT_BASE)
	# Title / muted variations: set label.theme_type_variation = "TitleLabel" etc.
	t.add_type("TitleLabel")
	t.set_type_variation("TitleLabel", "Label")
	t.set_font_size("font_size", "TitleLabel", FONT_TITLE)
	t.set_color("font_color", "TitleLabel", TEXT)
	t.set_color("font_outline_color", "TitleLabel", PANEL)
	t.set_constant("outline_size", "TitleLabel", 0)
	t.add_type("HugeLabel")
	t.set_type_variation("HugeLabel", "Label")
	t.set_font_size("font_size", "HugeLabel", FONT_HUGE)
	t.set_color("font_color", "HugeLabel", TEXT)
	t.add_type("MutedLabel")
	t.set_type_variation("MutedLabel", "Label")
	t.set_font_size("font_size", "MutedLabel", FONT_SMALL)
	t.set_color("font_color", "MutedLabel", TEXT_MUTED)
	# HUD text drawn over the 3D scene: white with dark outline for contrast
	t.add_type("HudLabel")
	t.set_type_variation("HudLabel", "Label")
	t.set_font_size("font_size", "HudLabel", FONT_LARGE)
	t.set_color("font_color", "HudLabel", Color.WHITE)
	t.set_color("font_outline_color", "HudLabel", INK)
	t.set_constant("outline_size", "HudLabel", 8)

	# Button (primary)
	var lip := 6
	t.set_stylebox("normal", "Button", _box(PRIMARY, PRIMARY_DARK, 0, RADIUS, 28, 14, lip))
	t.set_stylebox("hover", "Button", _box(PRIMARY.lightened(0.08), PRIMARY_DARK, 0, RADIUS, 28, 14, lip))
	var pressed := _box(PRIMARY_DARK, PRIMARY_DARK, 0, RADIUS, 28, 14, 0)
	pressed.content_margin_top = 14 + lip  # sinks down by the lip height
	t.set_stylebox("pressed", "Button", pressed)
	t.set_stylebox("disabled", "Button", _box(Color("#D8C8B2"), Color("#B8A68E"), 0, RADIUS, 28, 14, lip))
	var focus := _box(Color.TRANSPARENT, ACCENT, 4, RADIUS + 4)
	focus.expand_margin_left = 4
	focus.expand_margin_right = 4
	focus.expand_margin_top = 4
	focus.expand_margin_bottom = 4
	t.set_stylebox("focus", "Button", focus)
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		t.set_color(k, "Button", TEXT_ON_PRIMARY)
	t.set_color("font_disabled_color", "Button", Color("#8F7C66"))
	t.set_color("icon_normal_color", "Button", TEXT_ON_PRIMARY)
	t.set_font_size("font_size", "Button", FONT_LARGE)
	t.set_constant("h_separation", "Button", 12)
	t.set_constant("outline_size", "Button", 0)

	# Secondary button variation (blue)
	t.add_type("SecondaryButton")
	t.set_type_variation("SecondaryButton", "Button")
	var acc_dark := ACCENT.darkened(0.35)
	t.set_stylebox("normal", "SecondaryButton", _box(ACCENT, acc_dark, 0, RADIUS, 24, 12, lip))
	t.set_stylebox("hover", "SecondaryButton", _box(ACCENT.lightened(0.08), acc_dark, 0, RADIUS, 24, 12, lip))
	var spress := _box(acc_dark, acc_dark, 0, RADIUS, 24, 12, 0)
	spress.content_margin_top = 12 + lip
	t.set_stylebox("pressed", "SecondaryButton", spress)
	t.set_font_size("font_size", "SecondaryButton", FONT_BASE)

	# Quiet / ghost button (cream with border) for back, cancel
	t.add_type("GhostButton")
	t.set_type_variation("GhostButton", "Button")
	t.set_stylebox("normal", "GhostButton", _box(PANEL, PANEL_BORDER, 3, RADIUS, 20, 10))
	t.set_stylebox("hover", "GhostButton", _box(Color.WHITE, PANEL_BORDER, 3, RADIUS, 20, 10))
	t.set_stylebox("pressed", "GhostButton", _box(PANEL_BORDER, PANEL_BORDER, 3, RADIUS, 20, 10))
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		t.set_color(k, "GhostButton", TEXT)
	t.set_font_size("font_size", "GhostButton", FONT_BASE)

	# Panels
	var panel := _box(PANEL, PANEL_BORDER, 3, 24, 24, 20)
	panel.shadow_color = Color(0, 0, 0, 0.18)
	panel.shadow_size = 10
	panel.shadow_offset = Vector2(0, 4)
	t.set_stylebox("panel", "PanelContainer", panel)
	t.set_stylebox("panel", "Panel", panel)
	# Translucent dark HUD chip over the game view
	t.add_type("HudPanel")
	t.set_type_variation("HudPanel", "PanelContainer")
	t.set_stylebox("panel", "HudPanel", _box(Color(0.17, 0.11, 0.08, 0.55), Color.TRANSPARENT, 0, 16, 14, 6))

	# LineEdit
	var le := _box(Color.WHITE, PANEL_BORDER, 3, 14, 16, 12)
	t.set_stylebox("normal", "LineEdit", le)
	t.set_stylebox("focus", "LineEdit", _box(Color.TRANSPARENT, ACCENT, 3, 14))
	t.set_stylebox("read_only", "LineEdit", _box(PANEL, PANEL_BORDER, 3, 14, 16, 12))
	t.set_color("font_color", "LineEdit", TEXT)
	t.set_color("font_placeholder_color", "LineEdit", TEXT_MUTED)
	t.set_color("caret_color", "LineEdit", PRIMARY_DARK)
	t.set_color("selection_color", "LineEdit", Color(ACCENT, 0.35))
	t.set_font_size("font_size", "LineEdit", FONT_BASE)
	t.set_constant("minimum_character_width", "LineEdit", 4)

	# HSlider: thick rounded track, big grabber (40 px) for thumbs
	var track := _box(Color("#E3D3BC"), Color.TRANSPARENT, 0, 8, 0, 6)
	t.set_stylebox("slider", "HSlider", track)
	t.set_stylebox("grabber_area", "HSlider", _box(PRIMARY, Color.TRANSPARENT, 0, 8, 0, 6))
	t.set_stylebox("grabber_area_highlight", "HSlider", _box(PRIMARY.lightened(0.1), Color.TRANSPARENT, 0, 8, 0, 6))
	t.set_icon("grabber", "HSlider", _disc(40, Color.WHITE, PRIMARY_DARK, 5.0))
	t.set_icon("grabber_highlight", "HSlider", _disc(40, Color("#FFF3E6"), PRIMARY, 5.0))
	t.set_icon("grabber_disabled", "HSlider", _disc(40, Color("#EEE4D6"), Color("#B8A68E"), 5.0))
	t.set_constant("center_grabber", "HSlider", 0)
	t.set_constant("grabber_offset", "HSlider", 0)

	# CheckButton: big pill switch
	t.set_icon("checked", "CheckButton", _switch(true))
	t.set_icon("unchecked", "CheckButton", _switch(false))
	t.set_icon("checked_disabled", "CheckButton", _switch(true))
	t.set_icon("unchecked_disabled", "CheckButton", _switch(false))
	var empty := StyleBoxEmpty.new()
	empty.content_margin_top = 12
	empty.content_margin_bottom = 12
	for s in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		t.set_stylebox(s, "CheckButton", empty)
	t.set_stylebox("focus", "CheckButton", StyleBoxEmpty.new())
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		t.set_color(k, "CheckButton", TEXT)
	t.set_font_size("font_size", "CheckButton", FONT_BASE)
	t.set_constant("h_separation", "CheckButton", 16)

	# ProgressBar (XP / level progress)
	t.set_stylebox("background", "ProgressBar", _box(Color("#E3D3BC"), Color.TRANSPARENT, 0, 10, 0, 0))
	t.set_stylebox("fill", "ProgressBar", _box(GOLD, Color.TRANSPARENT, 0, 10, 0, 0))
	t.set_color("font_color", "ProgressBar", TEXT)
	t.set_font_size("font_size", "ProgressBar", FONT_SMALL)

	# Containers: comfortable spacing
	t.set_constant("separation", "VBoxContainer", GAP)
	t.set_constant("separation", "HBoxContainer", GAP)
	for m in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		t.set_constant(m, "MarginContainer", 24)

	return t


## Lane tint for lane index i (0-based); cb = colour-blind setting.
static func lane_color(i: int, cb: bool = false) -> Color:
	var arr: Array = LANE_COLORS_CB if cb else LANE_COLORS
	return arr[i % arr.size()]
