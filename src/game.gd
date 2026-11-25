extends Node
## App shell (autoload "Game"): loads content, owns the learning engine,
## settings, saving, music and sound, and passes speech through to the
## Speech autoload. Skins get this node as their `host`.

const Loader = preload("res://src/content/content_loader.gd")
const Storage = preload("res://src/storage/storage.gd")
const Clock = preload("res://src/engine/clock.gd")
const RunState = preload("res://src/skins/bokspring/run_state.gd")

const SKIN_ID := "bokspring"
const SFX := ["correct", "crash", "lane", "combo2", "combo3", "coin", "level_complete",
	"game_over", "tap", "new_record", "countdown"]
const DEFAULT_SETTINGS := {
	"music": 0.6, "sfx": 0.9, "speech": true, "speechRate": 1.0,
	"reduceMotion": false, "colorBlind": false, "reminderTime": "",
	"voiceNoticeShown": false,
}

signal settings_changed

var content: Dictionary = {}
var content_ok := false
var engine: LearningEngine
var run: Dictionary = {}          # Bokspring run state
var settings: Dictionary = {}
var _music: AudioStreamPlayer
var _music_name := ""
var _sfx_players: Array = []
var _sfx_streams: Dictionary = {}
var _sfx_next := 0
var _js_import_cb  # keeps the JS callback alive


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_audio()
	content = Loader.load_all()
	content_ok = content.ok
	if not content_ok:
		push_error("Content errors: %s" % str(content.errors))
	settings = DEFAULT_SETTINGS.duplicate()
	settings.merge(Storage.load_json(Storage.SETTINGS), true)
	_make_engine(Storage.load_json(Storage.PROGRESS))
	run = RunState.normalise(Storage.load_json(Storage.skin_path(SKIN_ID)))
	apply_settings()
	var sp := speech()
	if sp:
		sp.voices_checked.connect(_on_voices_checked)


func _make_engine(progress: Dictionary) -> void:
	engine = LearningEngine.new({"items": content.get("items", []), "units": content.get("units", [])},
		progress, Clock.today())


func refresh_day() -> void:
	engine.set_today(Clock.today())


# --- saving -----------------------------------------------------------------

func save() -> void:
	Storage.save_json(Storage.PROGRESS, engine.progress)
	Storage.save_json(Storage.skin_path(SKIN_ID), run)
	Storage.save_json(Storage.SETTINGS, settings)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_FOCUS_OUT \
			or what == NOTIFICATION_APPLICATION_PAUSED:
		if engine:
			save()


func reset_progress() -> void:
	Storage.wipe_all()
	var keep_audio := {"music": settings.music, "sfx": settings.sfx}
	settings = DEFAULT_SETTINGS.duplicate()
	settings.merge(keep_audio, true)
	_make_engine({})
	run = RunState.create()
	save()
	apply_settings()


# --- settings ---------------------------------------------------------------

func apply_settings() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(maxf(0.0001, float(settings.music))))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(maxf(0.0001, float(settings.sfx))))
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), float(settings.music) <= 0.01)
	AudioServer.set_bus_mute(AudioServer.get_bus_index("SFX"), float(settings.sfx) <= 0.01)
	var sp := speech()
	if sp:
		sp.enabled = bool(settings.speech)
		sp.rate = float(settings.speechRate)
	engine.listening_enabled = false  # listening challenges arrive in M2
	settings_changed.emit()


func set_setting(key: String, value) -> void:
	settings[key] = value
	apply_settings()
	Storage.save_json(Storage.SETTINGS, settings)


# --- speech -----------------------------------------------------------------

func speech() -> Node:
	return get_node_or_null("/root/Speech")


func has_afrikaans_voice() -> bool:
	var sp := speech()
	return sp != null and sp.has_afrikaans


func speak(text: String) -> void:
	var sp := speech()
	if sp and bool(settings.speech) and text != "":
		sp.speak(text)


## Call from the first tap: iOS only allows audio and speech after a gesture.
func unlock_audio() -> void:
	var sp := speech()
	if sp:
		sp.unlock()


signal voice_notice(message: String)


func _on_voices_checked(has_af: bool) -> void:
	if not has_af and not bool(settings.voiceNoticeShown):
		settings.voiceNoticeShown = true
		Storage.save_json(Storage.SETTINGS, settings)
		voice_notice.emit("This phone has no Afrikaans voice, so the game won't speak and listening challenges are off.\n\nIf your phone offers one, you can add it in Settings → Accessibility → Spoken Content → Voices.")


# --- audio ------------------------------------------------------------------

func _setup_audio() -> void:
	for bus in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus) == -1:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, bus)
			AudioServer.set_bus_send(i, "Master")
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	add_child(_music)
	for i in 6:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_sfx_players.append(p)
	for n in SFX:
		var path := "res://audio/sfx/%s.wav" % n
		if ResourceLoader.exists(path):
			_sfx_streams[n] = load(path)


func play_sfx(name: String, pitch: float = 1.0) -> void:
	var s = _sfx_streams.get(name)
	if s == null:
		return
	var p: AudioStreamPlayer = _sfx_players[_sfx_next]
	_sfx_next = (_sfx_next + 1) % _sfx_players.size()
	p.stream = s
	p.pitch_scale = pitch
	p.play()


func play_music(name: String) -> void:
	if name == _music_name and _music.playing:
		return
	var path := "res://audio/music/%s.ogg" % name
	if not ResourceLoader.exists(path):
		return
	var stream = load(path)
	if stream is AudioStreamOggVorbis:
		stream.loop = true
	_music_name = name
	_music.stream = stream
	_music.play()


func stop_music() -> void:
	_music.stop()
	_music_name = ""


# --- export / import ----------------------------------------------------------

func backup_text() -> String:
	return Storage.make_backup(engine.progress, {SKIN_ID: run}, settings)


## Returns "" on success or an error message.
func restore_backup(text: String) -> String:
	var r := Storage.parse_backup(text)
	if not r.ok:
		return r.error
	_make_engine(r.progress)
	run = RunState.normalise(r.skins.get(SKIN_ID, {}))
	settings = DEFAULT_SETTINGS.duplicate()
	settings.merge(r.settings, true)
	save()
	apply_settings()
	return ""


func export_progress() -> String:
	var text := backup_text()
	var name := "bokspring-backup-%s.json" % Time.get_date_string_from_system()
	if OS.has_feature("web"):
		JavaScriptBridge.download_buffer(text.to_utf8_buffer(), name, "application/json")
		return "Saved %s to your downloads." % name
	var path := OS.get_user_data_dir().path_join(name)
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()
	return "Saved to " + path


## On the web this opens the phone's file picker; `done` gets an error string ("" = ok).
func import_progress(done: Callable) -> void:
	if not OS.has_feature("web"):
		done.call("Import works in the web version. Paste the backup text instead.")
		return
	_js_import_cb = JavaScriptBridge.create_callback(func(args):
		var text := str(args[0]) if args.size() > 0 else ""
		if text == "":
			done.call("No file chosen.")
		else:
			done.call(restore_backup(text)))
	var window = JavaScriptBridge.get_interface("window")
	window.bokspringImportDone = _js_import_cb
	JavaScriptBridge.eval("""
		(function(){
			var i = document.createElement('input');
			i.type = 'file'; i.accept = '.json,application/json,text/plain';
			i.onchange = function(){
				var f = i.files && i.files[0];
				if (!f) { window.bokspringImportDone(''); return; }
				var r = new FileReader();
				r.onload = function(){ window.bokspringImportDone(String(r.result)); };
				r.readAsText(f);
			};
			i.click();
		})();
	""", true)
