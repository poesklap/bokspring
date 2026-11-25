extends RefCounted
## Small helpers for building menu screens in code.


static func page(parent: Control, scroll := false) -> VBoxContainer:
	var bg := ColorRect.new()
	bg.color = Style.BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	parent.add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for m in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + m, 24)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 32)
	parent.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	if scroll:
		var sc := ScrollContainer.new()
		sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		margin.add_child(sc)
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sc.add_child(box)
	else:
		margin.add_child(box)
	return box


static func label(parent: Control, text: String, variation := "", center := false) -> Label:
	var l := Label.new()
	l.text = text
	# Labels inside an HBox must not wrap (they'd shrink to one letter wide).
	if not parent is HBoxContainer:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if variation != "":
		l.theme_type_variation = StringName(variation)
	if center:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(l)
	return l


static func button(parent: Control, text: String, cb: Callable, variation := "") -> Button:
	var b := Button.new()
	b.text = text
	if variation != "":
		b.theme_type_variation = StringName(variation)
	b.pressed.connect(func():
		Game.unlock_audio()
		Game.play_sfx("tap")
		cb.call())
	parent.add_child(b)
	return b


static func spacer(parent: Control) -> Control:
	var c := Control.new()
	c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(c)
	return c


static func icon(path: String, size: int) -> TextureRect:
	var r := TextureRect.new()
	r.texture = load(path) if ResourceLoader.exists(path) else null
	r.custom_minimum_size = Vector2(size, size)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return r
