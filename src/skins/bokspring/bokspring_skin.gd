extends SkinBase
## Bokspring: a three-lane runner in the veld. Moving into the lane with the
## right answer is the only move. Implements SkinBase only.

const RunState = preload("res://src/skins/bokspring/run_state.gd")

signal go_menu

const ART := "res://assets/"
const VELD := "res://assets/arenas/veld/"
const LANE_W := 1.25
const BASE_SPEED := 9.0        # m/s at difficulty speed 1.0
const TRACK_LEN := 220.0
const TILE := 2.5              # metres per track texture tile (512 px)
const LEVEL_SIZE := 10
const SCENERY_SPAN := 34.0

enum S { IDLE, COUNTDOWN, RUN, CRASH, PANEL, PAUSED }

var state := S.IDLE
var world: Node3D
var cam: Camera3D
var player: AnimatedSprite3D
var track_mat: StandardMaterial3D
var grass_mat: StandardMaterial3D
var edge_mat: StandardMaterial3D
var scenery: Array = []
var gate: Node3D
var lane_marks: Node3D
var marked_lanes := -1
var obstacles: Array = []

var challenge: Dictionary = {}
var lanes := 3
var lane := 1
var committed := false
var chosen := -1
var resolved := false
var shown_ms := 0
var changed_ms := 0
var speed := 0.0
var target_speed := 0.0
var crash_slow := 0.0          # 0..1, slows after a crash and fades out
var level_time := 0.0
var level_coins := 0
var level_start_lives := 5
var _rng := RandomNumberGenerator.new()
var _next_pending := false

# HUD
var hud: CanvasLayer
var hearts: HBoxContainer
var coins_label: Label
var xp_label: Label
var level_label: Label
var dots: HBoxContainer
var prompt_label: Label
var prompt_hint: Label
var chips: VBoxContainer
var timer_bar: ProgressBar
var top_band: PanelContainer
var bottom_band: PanelContainer
var combo_label: Label
var center_label: Label
var pair_panel: PanelContainer
var pair_label: Label
var modal: Control
var swipe_hint: Label


func start(p_engine: LearningEngine, p_host: Node) -> void:
	super.start(p_engine, p_host)
	_rng.randomize()
	if world == null:
		_build_world()
		_build_hud()
	start_level()


# --- level flow ---------------------------------------------------------------

func start_level() -> void:
	_clear_modal()
	host.refresh_day()
	engine.start_round(LEVEL_SIZE)
	level_time = 0.0
	level_coins = 0
	level_start_lives = int(host.run.lives)
	_clear_gate()
	pair_panel.visible = false
	_set_player_crashed(false)
	lanes = 5
	lane = 2
	player.position.x = _lane_x(lane)
	prompt_label.text = ""
	prompt_hint.text = ""
	_clear_chips()
	_update_hud()
	host.play_music("run_loop")
	_countdown()


func _countdown() -> void:
	state = S.COUNTDOWN
	target_speed = _base_speed() * 0.6
	var steps := ["3", "2", "1", "Poesklap!"]
	for i in steps.size():
		if state != S.COUNTDOWN:
			return
		center_label.text = steps[i]
		center_label.visible = true
		_pop(center_label)
		host.play_sfx("countdown", 1.0 if i < 3 else 1.5)
		await get_tree().create_timer(0.45).timeout
	center_label.visible = false
	if state != S.COUNTDOWN:
		return
	state = S.RUN
	swipe_hint.visible = int(host.run.level) == 1 and int(engine.progress.stats.answers) < 6
	request_challenge()


func on_challenge(c: Dictionary) -> void:
	challenge = c
	lanes = c.options.size()
	lane = clampi(lane, 0, lanes - 1)
	_mark_lanes()
	_move_player_to_lane(false)
	committed = false
	resolved = false
	chosen = -1
	shown_ms = Time.get_ticks_msec()
	changed_ms = 0
	prompt_label.text = str(c.prompt)
	prompt_hint.text = "Tap the English" if c.type == "translate_af_en" else "Tap the Afrikaans"
	_pop(prompt_label)
	_fill_chips(c.options)
	timer_bar.max_value = float(c.timeLimitMs)
	timer_bar.value = float(c.timeLimitMs)
	timer_bar.visible = true
	target_speed = _current_speed()
	if c.type == "translate_af_en":
		host.speak(str(c.promptAudio))


func on_end(summary: Dictionary) -> void:
	state = S.PANEL
	target_speed = 0.0
	var record := RunState.complete_level(host.run, level_time)
	host.save()
	host.play_sfx("new_record" if record else "level_complete")
	_show_level_complete(summary, record)
	super.on_end(summary)


# --- per frame --------------------------------------------------------------------

func _process(delta: float) -> void:
	if state == S.PAUSED or world == null:
		return
	speed = move_toward(speed, target_speed, delta * (14.0 if target_speed < speed else 6.0))
	var dz := speed * delta
	if state == S.RUN or state == S.CRASH:
		level_time += delta
	# Scroll ground (texture moves toward the camera).
	track_mat.uv1_offset.y -= dz / TILE
	grass_mat.uv1_offset.y -= dz / (TILE * 1.6)
	edge_mat.uv1_offset.y -= dz / TILE
	for s in scenery:
		s.position.z += dz
		if s.position.z > 5.0:
			_place_scenery(s, s.position.z - SCENERY_SPAN)
	if player.sprite_frames and not player.animation == &"crash":
		player.speed_scale = clampf(speed / BASE_SPEED, 0.2, 1.6)
	if state == S.RUN and not challenge.is_empty() and not committed:
		var left := float(challenge.timeLimitMs) - (Time.get_ticks_msec() - shown_ms)
		timer_bar.value = maxf(0.0, left)
		if left <= 0.0:
			_select(-1)   # too slow: counts as a miss
	if gate:
		gate.position.z += dz
		if state == S.RUN and committed and not resolved and gate.position.z >= -0.2:
			_resolve()
		if gate and gate.position.z > 6.0:
			_clear_gate()
	if crash_slow > 0.0:
		crash_slow = maxf(0.0, crash_slow - delta * 0.08)
	_update_camera(delta)


func _update_camera(delta: float) -> void:
	var tx := player.position.x * 0.35
	cam.position.x = lerpf(cam.position.x, tx, minf(1.0, delta * 5.0))


# --- answering ------------------------------------------------------------------

## The player tapped answer `i` (-1 = ran out of time). The springbok moves
## into that lane, then obstacles appear in every wrong lane.
func _select(i: int) -> void:
	if state != S.RUN or committed or challenge.is_empty():
		return
	committed = true
	chosen = i
	changed_ms = Time.get_ticks_msec()
	swipe_hint.visible = false
	timer_bar.visible = false
	if i >= 0:
		lane = i
		host.play_sfx("lane")
		_move_player_to_lane(true)
	_highlight_chip(int(challenge.correctIndex), chosen)
	_spawn_obstacles()


func _resolve() -> void:
	resolved = true
	var correct := chosen == int(challenge.correctIndex)
	var ms := (changed_ms if changed_ms > 0 else Time.get_ticks_msec()) - shown_ms
	var r := report(challenge, correct, ms)
	if correct:
		_on_correct(r)
	else:
		_on_crash(r)


func _on_correct(r: Dictionary) -> void:
	host.play_sfx("correct")
	var coins := RunState.add_coins_for_correct(host.run, int(r.combo))
	level_coins += coins
	host.play_sfx("coin", 1.0 + 0.05 * mini(int(r.combo), 10))
	if int(r.combo) == 5:
		_show_combo("x2!", "combo2")
	elif int(r.combo) == 10:
		_show_combo("x3!", "combo3")
	if challenge.type == "translate_en_af":
		host.speak(str(challenge.pairAf))
	_update_hud("+%d XP" % int(r.xp))
	if r.roundComplete:
		await get_tree().create_timer(0.5).timeout
		on_end(engine.round_summary())
		return
	await get_tree().create_timer(0.35).timeout
	if state == S.RUN:
		request_challenge()
	elif state == S.PAUSED:
		_next_pending = true


func _on_crash(r: Dictionary) -> void:
	state = S.CRASH
	host.play_sfx("crash")
	_set_player_crashed(true)
	target_speed = 0.0
	speed *= 0.3
	crash_slow = 1.0
	if not bool(host.settings.reduceMotion):
		_shake()
	var over := RunState.lose_life(host.run)
	host.save()
	_update_hud()
	# Every mistake becomes a lesson: show the right pair with audio.
	pair_label.text = "%s\n=\n%s" % [challenge.pairAf, challenge.pairEn]
	pair_panel.visible = true
	_pop(pair_panel)
	host.speak(str(challenge.pairAf))
	await get_tree().create_timer(1.3).timeout
	pair_panel.visible = false
	_clear_gate()
	if over:
		_game_over()
		return
	_set_player_crashed(false)
	state = S.RUN
	await get_tree().create_timer(0.25).timeout
	if state == S.RUN:
		request_challenge()


func _game_over() -> void:
	state = S.PANEL
	target_speed = 0.0
	host.play_sfx("game_over")
	host.stop_music()
	var reached := int(host.run.level)
	RunState.game_over_reset(host.run)
	host.save()
	var box := _modal("Game over")
	_add_text(box, "You reached level %d." % reached)
	_add_text(box, "Your words are safe: everything you've learned is kept. Coins reset and you start again at level 1 with 5 lives.", true)
	var again := _add_button(box, "Weer!  (again)", "")
	again.pressed.connect(func():
		host.play_sfx("tap")
		start_level())
	var menu := _add_button(box, "Menu", "GhostButton")
	menu.pressed.connect(_exit_to_menu)
	again.grab_focus()


func _show_level_complete(summary: Dictionary, record: bool) -> void:
	var done_level := int(host.run.level) - 1
	var box := _modal("Vlak %d klaar!" % done_level)
	if record:
		var nr := _add_text(box, "Nuwe rekord!  %.1f s" % level_time)
		nr.add_theme_color_override("font_color", Style.PRIMARY)
		_pop(nr)
	else:
		_add_text(box, "Time %.1f s  (best %.1f s)" % [level_time, float(host.run.bestByLevel.get(str(done_level), level_time))])
	_add_text(box, "+%d XP    +%d coins    best combo %d" % [int(summary.xp), level_coins, int(summary.bestCombo)])
	_add_text(box, "Mistakes: %d    Lives left: %d" % [int(summary.wrong), int(host.run.lives)], true)
	var unlock: Dictionary = engine.next_unlock()
	if not unlock.is_empty():
		_add_text(box, "%d XP to unlock \"%s\"" % [int(unlock.xpNeeded), unlock.unit.titleEn], true)
	var tip := _tip_for(done_level)
	if not tip.is_empty():
		var tp := PanelContainer.new()
		var tv := VBoxContainer.new()
		tp.add_child(tv)
		var tt := Label.new()
		tt.text = "Tip: " + str(tip.titleEn)
		tt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tv.add_child(tt)
		var tb := Label.new()
		tb.text = str(tip.bodyEn)
		tb.theme_type_variation = &"MutedLabel"
		tb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tv.add_child(tb)
		for ex in tip.get("examples", []):
			var el := Label.new()
			el.text = "%s  =  %s" % [ex.af, ex.en]
			tv.add_child(el)
		box.add_child(tp)
	_add_text(box, "The shop opens in the next update.", true)
	var next := _add_button(box, "Volgende vlak  (next level)", "")
	next.pressed.connect(func():
		host.play_sfx("tap")
		start_level())
	var menu := _add_button(box, "Menu", "GhostButton")
	menu.pressed.connect(_exit_to_menu)


func _tip_for(level: int) -> Dictionary:
	var seen: Array = engine.progress.seenTips
	for tip in host.content.get("tips", []):
		if int(tip.showAfterLevel) <= level and not seen.has(tip.id):
			seen.append(tip.id)
			host.save()
			return tip
	return {}


func _exit_to_menu() -> void:
	host.play_sfx("tap")
	state = S.IDLE
	target_speed = 0.0
	_clear_modal()
	_clear_gate()
	go_menu.emit()


# --- input ------------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	# Desktop testing: number keys pick an answer.
	if event is InputEventKey and event.pressed and not event.echo:
		var n: int = event.keycode - KEY_1
		if n >= 0 and n < lanes:
			_select(n)





func _move_player_to_lane(animate: bool) -> void:
	var x := _lane_x(lane)
	if animate and not bool(host.settings.reduceMotion):
		create_tween().tween_property(player, "position:x", x, 0.12).set_trans(Tween.TRANS_SINE)
	else:
		player.position.x = x


func _lane_x(i: int) -> float:
	return (i - (lanes - 1) / 2.0) * LANE_W


func _base_speed() -> float:
	return BASE_SPEED * float(engine.profile().speed)


## Speeds up with the combo, slows after a crash.
func _current_speed() -> float:
	var combo := engine.session.combo if engine.session else 0
	return _base_speed() * (1.0 + 0.04 * mini(combo, 12)) * (1.0 - 0.3 * crash_slow)


# --- world ------------------------------------------------------------------------

func _tex(path: String) -> Texture2D:
	return load(path) if ResourceLoader.exists(path) else null


func _build_world() -> void:
	world = Node3D.new()
	add_child(world)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#9fd3f0")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#fff1dc")
	env.ambient_light_energy = 0.6
	env.fog_enabled = true
	env.fog_light_color = Color("#c99a6b")
	env.fog_density = 0.012
	env.fog_sky_affect = 0.0
	var we := WorldEnvironment.new()
	we.environment = env
	world.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -30, 0)
	sun.light_color = Color("#ffe2b0")
	sun.light_energy = 1.0
	world.add_child(sun)

	cam = Camera3D.new()
	cam.keep_aspect = Camera3D.KEEP_WIDTH
	cam.fov = 64.0
	# High, looking down: the horizon is hidden behind the top HUD band.
	cam.position = Vector3(0, 5.1, 1.7)
	cam.rotation_degrees = Vector3(-55, 0, 0)
	cam.far = 260.0
	world.add_child(cam)
	cam.current = true

	# Sky backdrop with koppies on the horizon (not fogged).
	var sky_tex := _tex(VELD + "sky.svg")
	if sky_tex:
		var sky := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(600, 300)
		sky.mesh = q
		var sm := StandardMaterial3D.new()
		sm.albedo_texture = sky_tex
		sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		sm.disable_fog = true
		sm.texture_repeat = true
		sm.uv1_scale = Vector3(600.0 / 512.0, 1, 1)
		sky.material_override = sm
		sky.position = Vector3(0, 300 * 0.5 - 22, -210)
		world.add_child(sky)

	# Ground: grass everywhere, dirt track in the middle.
	grass_mat = _ground_material(VELD + "ground_grass.svg", Color("#d9a441"))
	var grass := MeshInstance3D.new()
	var gm := PlaneMesh.new()
	gm.size = Vector2(160, TRACK_LEN)
	grass.mesh = gm
	grass.material_override = grass_mat
	grass_mat.uv1_scale = Vector3(160 / (TILE * 1.6), TRACK_LEN / (TILE * 1.6), 1)
	grass.position = Vector3(0, -0.01, -TRACK_LEN / 2 + 10)
	world.add_child(grass)
	track_mat = _ground_material(VELD + "ground_track.svg", Color("#b5562f"))
	var track := MeshInstance3D.new()
	var tm := PlaneMesh.new()
	tm.size = Vector2(LANE_W * 5 + 0.8, TRACK_LEN)
	track.mesh = tm
	track.material_override = track_mat
	track_mat.uv1_scale = Vector3(tm.size.x / TILE, TRACK_LEN / TILE, 1)
	track.position = Vector3(0, 0, -TRACK_LEN / 2 + 10)
	world.add_child(track)
	# Stony, grassy borders along both sides of the track.
	edge_mat = _ground_material(VELD + "track_edge.svg", Color(0, 0, 0, 0))
	edge_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	edge_mat.alpha_scissor_threshold = 0.3
	edge_mat.uv1_scale = Vector3(1, TRACK_LEN / TILE, 1)
	for side in [-1.0, 1.0]:
		var edge := MeshInstance3D.new()
		var em := PlaneMesh.new()
		em.size = Vector2(TILE * 0.25, TRACK_LEN)
		edge.mesh = em
		edge.material_override = edge_mat
		edge.position = Vector3(side * (tm.size.x / 2 + em.size.x / 2 - 0.2), 0.008, -TRACK_LEN / 2 + 10)
		if side < 0:
			edge.scale.x = -1  # mirror: the stony side faces the track
		world.add_child(edge)

	# Scenery along both sides.
	var kinds := [["acacia.svg", 512, 5.0], ["bush.svg", 256, 1.6], ["grass_tuft.svg", 128, 0.8],
		["koppie_rock.svg", 256, 2.2], ["termite_mound.svg", 256, 1.8], ["acacia_tall.svg", 512, 5.5],
		["grass_clump.svg", 128, 0.9], ["aloe.svg", 256, 1.7], ["rocks_cluster.svg", 128, 1.0],
		["fence_post.svg", 256, 1.3], ["dead_tree.svg", 512, 4.5], ["grass_tuft.svg", 128, 0.7],
		["bush.svg", 256, 1.4], ["grass_clump.svg", 128, 0.8], ["aloe.svg", 256, 1.4]]
	for i in 44:
		var k = kinds[i % kinds.size()]
		var s := _billboard(VELD + k[0], k[1], k[2])
		world.add_child(s)
		_place_scenery(s, 5.0 - _rng.randf_range(0, SCENERY_SPAN))
		scenery.append(s)

	# The springbok.
	player = AnimatedSprite3D.new()
	var frames := SpriteFrames.new()
	frames.add_animation(&"run")
	frames.set_animation_speed(&"run", 12.0)
	for i in 6:
		var t := _tex(ART + "springbok/run_%d.svg" % i)
		if t:
			frames.add_frame(&"run", t)
	frames.add_animation(&"crash")
	var ct := _tex(ART + "springbok/crash.svg")
	if ct:
		frames.add_frame(&"crash", ct)
	player.sprite_frames = frames
	player.pixel_size = 2.6 / 256.0
	player.offset = Vector2(0, 113)
	player.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	player.shaded = false
	player.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	player.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	player.position = Vector3(0, 0, 0)
	world.add_child(player)
	player.play(&"run")


func _ground_material(path: String, fallback: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	var t := _tex(path)
	if t:
		m.albedo_texture = t
	else:
		m.albedo_color = fallback
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	m.texture_repeat = true
	m.roughness = 1.0
	return m


func _billboard(path: String, px: int, height_m: float) -> Sprite3D:
	var s := Sprite3D.new()
	s.texture = _tex(path)
	s.pixel_size = height_m / float(px)
	s.offset = Vector2(0, px / 2.0 - 4)
	s.billboard = BaseMaterial3D.BILLBOARD_ENABLED  # stand up toward the high camera
	s.shaded = false
	s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return s


func _place_scenery(s: Node3D, z: float) -> void:
	var side := -1.0 if _rng.randf() < 0.5 else 1.0
	# Only the near veld is on screen with the high camera, so keep props close.
	s.position = Vector3(side * _rng.randf_range(LANE_W * 2.5 + 0.6, 8.0), 0, z - _rng.randf_range(0, 1.5))


func _spawn_obstacles() -> void:
	_clear_gate()
	gate = Node3D.new()
	world.add_child(gate)
	gate.position.z = _offscreen_z()
	for i in lanes:
		# The right lane stays clear, unless time ran out and the springbok is standing in it.
		if i == int(challenge.correctIndex) and not (chosen < 0 and i == lane):
			continue
		var o := _make_obstacle()
		gate.add_child(o)
		o.position = Vector3(_lane_x(i), 0.0, 0.0)
		obstacles.append(o)
		if not bool(host.settings.reduceMotion):
			o.scale = Vector3(0.2, 0.2, 0.2)
			create_tween().tween_property(o, "scale", Vector3.ONE, 0.15).set_trans(Tween.TRANS_BACK)


## Ground z just hidden behind the top HUD band (plus room for the obstacle's
## height), so new obstacles slide into view rather than popping up.
func _offscreen_z() -> float:
	var y := top_band.get_global_rect().end.y if top_band else 0.0
	var vp := get_viewport().get_visible_rect().size
	var origin := cam.project_ray_origin(Vector2(vp.x / 2, y))
	var dir := cam.project_ray_normal(Vector2(vp.x / 2, y))
	if dir.y >= -0.01:
		return -14.0
	var t := -origin.y / dir.y
	var z := origin.z + dir.z * t
	return minf(z - 2.0, -6.0)


## Clear lane markings along the whole track: tinted lanes with bright dividers.
func _mark_lanes() -> void:
	if marked_lanes == lanes and lane_marks:
		return
	marked_lanes = lanes
	if lane_marks:
		lane_marks.queue_free()
	lane_marks = Node3D.new()
	world.add_child(lane_marks)
	var cb := bool(host.settings.colorBlind)
	var length := TRACK_LEN
	for i in lanes:
		var strip := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(LANE_W - 0.08, length)
		strip.mesh = pm
		var sm := StandardMaterial3D.new()
		sm.albedo_color = Style.lane_color(i, cb)
		sm.albedo_color.a = 0.2
		sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		strip.material_override = sm
		strip.position = Vector3(_lane_x(i), 0.012, -length / 2 + 10)
		lane_marks.add_child(strip)
	for i in lanes + 1:
		var line := MeshInstance3D.new()
		var lm := PlaneMesh.new()
		lm.size = Vector2(0.09, length)
		line.mesh = lm
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color("#fff4dc")
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		line.material_override = mat
		line.position = Vector3((i - lanes / 2.0) * LANE_W, 0.02, -length / 2 + 10)
		lane_marks.add_child(line)


func _make_obstacle() -> Sprite3D:
	var pick: String = ["obstacle_rock.svg", "obstacle_thorn.svg", "obstacle_log.svg"][_rng.randi() % 3]
	var px := 128 if pick == "obstacle_log.svg" else 256
	var s := _billboard(VELD + pick, px, 1.25 if px == 256 else 0.7)
	if px == 128:
		s.pixel_size = 1.4 / 256.0
		s.offset = Vector2(0, 60)
	return s


func _clear_gate() -> void:
	if gate:
		gate.queue_free()
	gate = null
	obstacles.clear()


func _set_player_crashed(on: bool) -> void:
	if player.sprite_frames == null:
		return
	if on and player.sprite_frames.get_frame_count(&"crash") > 0:
		player.play(&"crash")
	else:
		player.play(&"run")


func _shake() -> void:
	var t := create_tween()
	var base := cam.position
	for i in 6:
		t.tween_property(cam, "position", base + Vector3(_rng.randf_range(-0.12, 0.12), _rng.randf_range(-0.08, 0.08), 0), 0.04)
	t.tween_property(cam, "position", base, 0.05)


# --- HUD ----------------------------------------------------------------------------

func _build_hud() -> void:
	hud = CanvasLayer.new()
	add_child(hud)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = Style.make_theme()
	hud.add_child(root)

	# Solid bands top and bottom frame the track; the horizon sits behind the
	# top band, so obstacles slide in from off-screen instead of popping up.
	top_band = PanelContainer.new()
	top_band.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_band.add_theme_stylebox_override("panel", _band_style(true))
	root.add_child(top_band)
	var top := MarginContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for m in ["left", "right"]:
		top.add_theme_constant_override("margin_" + m, 16)
	top.add_theme_constant_override("margin_top", 14)
	top.add_theme_constant_override("margin_bottom", 12)
	top_band.add_child(top)
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_theme_constant_override("separation", 8)
	top.add_child(col)

	var bar := HBoxContainer.new()
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(bar)
	hearts = HBoxContainer.new()
	hearts.add_theme_constant_override("separation", 2)
	bar.add_child(hearts)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(sp)
	coins_label = _hud_label(26)
	bar.add_child(_icon(ART + "ui/coin_small.svg", 28))
	bar.add_child(coins_label)
	xp_label = _hud_label(26)
	bar.add_child(_icon(ART + "ui/xp_star.svg", 28))
	bar.add_child(xp_label)
	var pause := Button.new()
	pause.text = "II"
	pause.custom_minimum_size = Vector2(64, 64)
	pause.theme_type_variation = &"GhostButton"
	pause.pressed.connect(_pause)
	bar.add_child(pause)

	var row2 := HBoxContainer.new()
	row2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(row2)
	level_label = _hud_label(22)
	row2.add_child(level_label)
	dots = HBoxContainer.new()
	dots.add_theme_constant_override("separation", 6)
	dots.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dots.alignment = BoxContainer.ALIGNMENT_END
	row2.add_child(dots)

	var pp := PanelContainer.new()
	pp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(pp)
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 0)
	pp.add_child(pv)
	prompt_hint = _hud_label(20)
	prompt_hint.theme_type_variation = &"MutedLabel"
	prompt_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pv.add_child(prompt_hint)
	prompt_label = _hud_label(48)
	prompt_label.theme_type_variation = &""
	prompt_label.add_theme_color_override("font_color", Style.TEXT)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prompt_label.custom_minimum_size = Vector2(0, 64)
	pv.add_child(prompt_label)

	timer_bar = ProgressBar.new()
	timer_bar.show_percentage = false
	timer_bar.custom_minimum_size = Vector2(0, 12)
	timer_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	timer_bar.visible = false
	col.add_child(timer_bar)

	# The answers: stacked buttons at the bottom; each shows its lane.
	bottom_band = PanelContainer.new()
	bottom_band.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_band.grow_vertical = Control.GROW_DIRECTION_BEGIN
	bottom_band.add_theme_stylebox_override("panel", _band_style(false))
	root.add_child(bottom_band)
	var bottom := MarginContainer.new()
	for m in ["left", "right"]:
		bottom.add_theme_constant_override("margin_" + m, 14)
	bottom.add_theme_constant_override("margin_top", 12)
	bottom.add_theme_constant_override("margin_bottom", 26)
	bottom_band.add_child(bottom)
	chips = VBoxContainer.new()
	chips.add_theme_constant_override("separation", 8)
	bottom.add_child(chips)

	combo_label = _hud_label(96)
	combo_label.set_anchors_preset(Control.PRESET_CENTER)
	combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	combo_label.add_theme_color_override("font_color", Style.GOLD)
	combo_label.visible = false
	root.add_child(combo_label)
	center_label = _hud_label(96)
	center_label.set_anchors_preset(Control.PRESET_CENTER)
	center_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	center_label.visible = false
	root.add_child(center_label)

	pair_panel = PanelContainer.new()
	pair_panel.set_anchors_preset(Control.PRESET_CENTER)
	pair_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	pair_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	pair_panel.custom_minimum_size = Vector2(420, 0)
	pair_panel.visible = false
	root.add_child(pair_panel)
	pair_label = Label.new()
	pair_label.add_theme_font_size_override("font_size", 44)
	pair_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pair_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pair_panel.add_child(pair_label)

	swipe_hint = _hud_label(30)
	swipe_hint.text = "Tap the right answer\nto run into its lane"
	swipe_hint.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	swipe_hint.offset_top = -300
	swipe_hint.offset_bottom = -190
	swipe_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	swipe_hint.visible = false
	root.add_child(swipe_hint)

	modal = Control.new()
	modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal.visible = false
	root.add_child(modal)


func _hud_label(size: int) -> Label:
	var l := Label.new()
	l.theme_type_variation = &"HudLabel"
	l.add_theme_font_size_override("font_size", size)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _icon(path: String, size: int) -> TextureRect:
	var r := TextureRect.new()
	r.texture = _tex(path)
	r.custom_minimum_size = Vector2(size, size)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


func _update_hud(xp_pop: String = "") -> void:
	for c in hearts.get_children():
		c.queue_free()
	for i in 5:
		hearts.add_child(_icon(ART + ("ui/heart.svg" if i < int(host.run.lives) else "ui/heart_empty.svg"), 34))
	coins_label.text = str(int(host.run.coins))
	xp_label.text = str(int(engine.progress.xp))
	level_label.text = "Vlak %d" % int(host.run.level)
	for c in dots.get_children():
		c.queue_free()
	var done := engine.session.done_count() if engine.session else 0
	var total := engine.session.size() if engine.session else LEVEL_SIZE
	for i in total:
		var d := ColorRect.new()
		d.custom_minimum_size = Vector2(18, 18)
		d.color = Style.GOLD if i < done else Color(1, 1, 1, 0.45)
		dots.add_child(d)
	if xp_pop != "":
		var l := _hud_label(30)
		l.text = xp_pop
		l.add_theme_color_override("font_color", Style.GOLD)
		hud.get_child(0).add_child(l)
		l.position = Vector2(get_viewport().get_visible_rect().size.x / 2 - 50, get_viewport().get_visible_rect().size.y * 0.55)
		var t := create_tween()
		t.tween_property(l, "position:y", l.position.y - 80, 0.7)
		t.parallel().tween_property(l, "modulate:a", 0.0, 0.7)
		t.tween_callback(l.queue_free)


func _clear_chips() -> void:
	for c in chips.get_children():
		c.queue_free()


func _fill_chips(options: Array) -> void:
	_clear_chips()
	var cb := bool(host.settings.colorBlind)
	for i in options.size():
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 66)
		b.focus_mode = Control.FOCUS_NONE
		var col: Color = Style.lane_color(i, cb)
		for st in ["normal", "hover", "pressed", "disabled", "focus"]:
			var sb := StyleBoxFlat.new()
			sb.bg_color = col if st != "pressed" else col.darkened(0.15)
			sb.set_corner_radius_all(16)
			sb.content_margin_left = 12
			sb.content_margin_right = 12
			sb.border_color = Color.WHITE
			sb.set_border_width_all(0)
			b.add_theme_stylebox_override(st, sb)
		var row := HBoxContainer.new()
		row.set_anchors_preset(Control.PRESET_FULL_RECT)
		row.offset_left = 12
		row.offset_right = -12
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override("separation", 12)
		b.add_child(row)
		row.add_child(_lane_marker(i, options.size()))
		var l := Label.new()
		l.text = str(options[i])
		l.add_theme_font_size_override("font_size", 27)
		l.add_theme_color_override("font_color", Style.TEXT)
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.size_flags_vertical = Control.SIZE_FILL
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(l)
		var idx: int = i
		b.pressed.connect(func(): _select(idx))
		chips.add_child(b)


## A tiny picture of the lanes with this button's lane filled in.
func _lane_marker(i: int, n: int) -> Control:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for k in n:
		var r := ColorRect.new()
		r.custom_minimum_size = Vector2(9, 26)
		r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		r.color = Style.TEXT if k == i else Color(Style.TEXT, 0.22)
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(r)
	return box


func _band_style(top: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#3A2416")
	if top:
		sb.corner_radius_bottom_left = 22
		sb.corner_radius_bottom_right = 22
	else:
		sb.corner_radius_top_left = 22
		sb.corner_radius_top_right = 22
	sb.shadow_color = Color(0, 0, 0, 0.3)
	sb.shadow_size = 6
	return sb

func _highlight_chip(correct: int, current: int) -> void:
	var i := 0
	for b in chips.get_children():
		b.disabled = correct >= 0
		var sb: StyleBoxFlat = b.get_theme_stylebox("disabled" if correct >= 0 else "normal")
		sb.set_border_width_all(0)
		if i == current:
			sb.border_color = Color.WHITE
			sb.set_border_width_all(6)
		if correct >= 0 and i == correct:
			sb.border_color = Style.GOOD
			sb.set_border_width_all(8)
		b.modulate = Color(1, 1, 1, 1.0 if (correct < 0 or i == correct or i == current) else 0.45)
		i += 1


func _show_combo(text: String, sfx: String) -> void:
	host.play_sfx(sfx)
	combo_label.text = text
	combo_label.visible = true
	_pop(combo_label, 1.8)
	await get_tree().create_timer(0.9).timeout
	combo_label.visible = false


func _pop(c: CanvasItem, amount: float = 1.25) -> void:
	if bool(host.settings.reduceMotion) or not c is Control:
		return
	var ctl := c as Control
	ctl.pivot_offset = ctl.size / 2
	ctl.scale = Vector2.ONE * amount
	create_tween().tween_property(ctl, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)


# --- modal panels -----------------------------------------------------------------

func _modal(title: String) -> VBoxContainer:
	_clear_modal()
	modal.visible = true
	var dim := ColorRect.new()
	dim.color = Style.SHADE
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(470, 0)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	var t := Label.new()
	t.text = title
	t.theme_type_variation = &"TitleLabel"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(t)
	return box


func _add_text(box: Control, text: String, muted := false) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.custom_minimum_size = Vector2(430, 0)
	if muted:
		l.theme_type_variation = &"MutedLabel"
	box.add_child(l)
	return l


func _add_button(box: Control, text: String, variation: String) -> Button:
	var b := Button.new()
	b.text = text
	if variation != "":
		b.theme_type_variation = StringName(variation)
	box.add_child(b)
	return b


func _clear_modal() -> void:
	if modal == null:
		return
	for c in modal.get_children():
		c.queue_free()
	modal.visible = false


func _pause() -> void:
	if state != S.RUN:
		return
	host.play_sfx("tap")
	var prev := state
	state = S.PAUSED
	var box := _modal("Pause")
	_add_text(box, "Leaving now restarts this level next time. Lives already lost stay lost.", true)
	var go := _add_button(box, "Speel verder  (resume)", "")
	go.pressed.connect(func():
		host.play_sfx("tap")
		_clear_modal()
		state = prev
		if _next_pending:
			_next_pending = false
			request_challenge())
	var menu := _add_button(box, "Menu", "GhostButton")
	menu.pressed.connect(_exit_to_menu)
