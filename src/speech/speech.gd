extends Node
## Speech: speaks Afrikaans with the device's own voice (no network, no paid service).
##
## Autoload as `Speech`. Uses DisplayServer TTS (browser speechSynthesis on web) and,
## on web, JavaScriptBridge as a second source of truth for the voice list and as a
## fallback speaker. If the device has no Afrikaans voice it speaks NOTHING: an
## English voice reading Afrikaans would teach the wrong sounds.
##
## Needs project setting `audio/general/text_to_speech=true` for the DisplayServer path.
##
## voices_checked is emitted once detection finishes. It can be emitted a second time
## with `true` if an Afrikaans voice only shows up later (e.g. iOS lists voices after
## the first tap). Show the "add an Afrikaans voice in your phone settings" notice only
## once (persist that in the save file) and only when has_afrikaans is false.

signal voices_checked(has_afrikaans: bool)

const POLL_INTERVAL := 0.25   # seconds between voice-list polls
const POLL_TIMEOUT := 3.0     # give up after this long
const RATE_MIN := 0.5
const RATE_MAX := 1.5

var checked: bool = false        ## true once detection finished
var has_afrikaans: bool = false
var voice_name: String = ""      ## chosen voice, "" if none
var enabled: bool = true         ## user setting (speech on/off)
var rate: float = 1.0            ## user setting 0.5-1.5
var volume: int = 100            ## 0-100

var _voice_id: String = ""       # DisplayServer voice id ("" when speaking through JS)
var _voice_lang: String = ""     # e.g. "af-ZA"
var _source: String = ""         # "displayserver", "javascript" or ""
var _ds_voices: Array = []       # [{name, language, id}]
var _js_voices: Array = []       # [{name, lang, local}]
var _polls: int = 0
var _elapsed: float = 0.0
var _polling: bool = false
var _unlocked: bool = false
var _is_web: bool = false
var _ds_tts: bool = false        # DisplayServer TTS usable
var _js_ok: bool = false         # JavaScriptBridge usable
var _errors: Array = []


func _ready() -> void:
	_is_web = OS.has_feature("web")
	_ds_tts = _detect_ds_tts()
	if _is_web:
		_js_ok = _js_install()
	_start_polling()


# --------------------------------------------------------------------- public API

## Call from the first button press. On iOS Safari speech only works after a user
## gesture; on web a DOM-level tap listener (installed in _ready) also does this inside
## the real browser event, which is what Safari actually requires.
func unlock() -> void:
	if _unlocked:
		return
	_unlocked = true
	if _js_ok:
		_js_eval("window.__bokspringSpeech && window.__bokspringSpeech.unlock();")
	elif _ds_tts and _voice_id != "":
		DisplayServer.tts_speak(" ", _voice_id, 0, 1.0, 1.0, 0, true)
	# Some browsers only reveal voices after a gesture: look again if we found none.
	if checked and not has_afrikaans:
		_start_polling()


## Speaks `text` with the Afrikaans voice. Stops any current utterance first.
## No-op when speech is off or the device has no Afrikaans voice.
func speak(text: String) -> void:
	if not enabled or not has_afrikaans or text.strip_edges() == "":
		return
	var r: float = clampf(rate, RATE_MIN, RATE_MAX)
	if _source == "displayserver" and _ds_tts:
		DisplayServer.tts_stop()
		DisplayServer.tts_speak(text, _voice_id, clampi(volume, 0, 100), 1.0, r, 0, true)
	elif _source == "javascript" and _js_ok:
		var js := "window.__bokspringSpeech && window.__bokspringSpeech.speak(%s, %s, %s, %f, %f);" % [
			_js_str(text), _js_str(voice_name), _js_str(_voice_lang), r, clampi(volume, 0, 100) / 100.0]
		_js_eval(js)


func stop() -> void:
	if _ds_tts:
		DisplayServer.tts_stop()
	if _js_ok:
		_js_eval("window.speechSynthesis && window.speechSynthesis.cancel();")


func is_speaking() -> bool:
	if _source == "displayserver" and _ds_tts:
		return DisplayServer.tts_is_speaking()
	if _source == "javascript" and _js_ok:
		return _js_eval("!!(window.speechSynthesis && window.speechSynthesis.speaking)") == true
	return false


## Everything a diagnostics screen needs to check speech on a real iPhone.
func debug_report() -> Dictionary:
	var ua := ""
	if _js_ok:
		var v = _js_eval("navigator.userAgent")
		if v is String:
			ua = v
	return {
		"platform": OS.get_name(),
		"web": _is_web,
		"user_agent": ua,
		"project_setting_tts": bool(ProjectSettings.get_setting("audio/general/text_to_speech", false)),
		"displayserver_tts": _ds_tts,
		"javascript_bridge": _js_ok,
		"checked": checked,
		"has_afrikaans": has_afrikaans,
		"voice_name": voice_name,
		"voice_id": _voice_id,
		"voice_language": _voice_lang,
		"source": _source,
		"enabled": enabled,
		"rate": rate,
		"unlocked": _unlocked,
		"js_unlocked": _js_ok and _js_eval("!!(window.__bokspringSpeech && window.__bokspringSpeech.unlocked)") == true,
		"polls": _polls,
		"displayserver_voices": _ds_voices.duplicate(true),
		"javascript_voices": _js_voices.duplicate(true),
		"errors": _errors.duplicate(),
	}


# --------------------------------------------------------------------- detection

var _round_polls: int = 0   # polls in the current detection round


func _start_polling() -> void:
	_polling = true
	_elapsed = 0.0
	_round_polls = 0
	set_process(true)
	_poll()


func _process(delta: float) -> void:
	if not _polling:
		set_process(false)
		return
	_elapsed += delta
	if _elapsed >= POLL_INTERVAL * _round_polls:
		_poll()


func _poll() -> void:
	_polls += 1
	_round_polls += 1
	_read_voices()
	var found := _choose_voice()
	if found or _elapsed >= POLL_TIMEOUT:
		_polling = false
		set_process(false)
		var was_checked := checked
		var had := has_afrikaans
		checked = true
		has_afrikaans = found
		if not was_checked or (found and not had):
			voices_checked.emit(has_afrikaans)


func _read_voices() -> void:
	if _ds_tts:
		_ds_voices = []
		for v in DisplayServer.tts_get_voices():
			if v is Dictionary:
				_ds_voices.append({
					"name": str(v.get("name", "")),
					"language": str(v.get("language", "")),
					"id": str(v.get("id", "")),
				})
	if _js_ok:
		var s = _js_eval("window.__bokspringSpeech ? window.__bokspringSpeech.voices() : '[]'")
		if s is String and s != "":
			var parsed = JSON.parse_string(s)
			if parsed is Array:
				_js_voices = parsed


func _choose_voice() -> bool:
	# 1. DisplayServer (the normal path, also what Godot uses to speak).
	if _ds_tts:
		var best := {}
		var best_score := -1
		for v in _ds_voices:
			var sc := _lang_score(v["language"])
			if sc > best_score and sc > 0:
				best_score = sc
				best = v
		# tts_get_voices_for_language as a cross-check (codes may be formatted differently)
		if best.is_empty():
			for lang in ["af", "af_ZA", "af-ZA"]:
				var ids := DisplayServer.tts_get_voices_for_language(lang)
				if ids.size() > 0:
					for v in _ds_voices:
						if v["id"] == ids[0]:
							best = v
					if best.is_empty():
						best = {"name": ids[0], "language": lang, "id": ids[0]}
					break
		if not best.is_empty():
			_voice_id = best["id"]
			voice_name = best["name"]
			_voice_lang = str(best["language"]).replace("_", "-")
			_source = "displayserver"
			return true
	# 2. Browser speechSynthesis seen directly through JavaScriptBridge.
	if _js_ok:
		var best_js := {}
		var best_js_score := -1
		for v in _js_voices:
			if not (v is Dictionary):
				continue
			var sc := _lang_score(str(v.get("lang", "")))
			if sc > 0:
				if bool(v.get("local", false)):
					sc += 1  # prefer on-device voices: work offline
				if sc > best_js_score:
					best_js_score = sc
					best_js = v
		if not best_js.is_empty():
			voice_name = str(best_js.get("name", ""))
			_voice_lang = str(best_js.get("lang", "af-ZA"))
			# If DisplayServer can speak with a voice of the same name, prefer it.
			_voice_id = ""
			_source = "javascript"
			if _ds_tts:
				for v in _ds_voices:
					if v["name"] == voice_name:
						_voice_id = v["id"]
						_source = "displayserver"
			return true
	_voice_id = ""
	voice_name = ""
	_voice_lang = ""
	_source = ""
	return false


## 0 = not Afrikaans, 2 = Afrikaans, 3 = Afrikaans (South Africa).
func _lang_score(code: String) -> int:
	var c := code.strip_edges().to_lower().replace("-", "_")
	if c == "af_za":
		return 3
	if c == "af" or c == "afr" or c.begins_with("af_") or c.begins_with("afr_"):
		return 2
	return 0


func _detect_ds_tts() -> bool:
	if not bool(ProjectSettings.get_setting("audio/general/text_to_speech", false)):
		_errors.append("audio/general/text_to_speech is off in project.godot")
		return false
	if not DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		_errors.append("DisplayServer has no text-to-speech on this platform")
		return false
	return true


# --------------------------------------------------------------------- web helpers

const _JS_SETUP := """
(function () {
  if (window.__bokspringSpeech) return true;
  var synth = window.speechSynthesis;
  if (!synth || typeof SpeechSynthesisUtterance === 'undefined') return false;
  var api = { unlocked: false, list: [] };
  function refresh() {
    try {
      api.list = synth.getVoices().map(function (v) {
        return { name: v.name, lang: v.lang, local: !!v.localService };
      });
    } catch (e) {}
  }
  api.voices = function () { refresh(); return JSON.stringify(api.list); };
  api.unlock = function () {
    if (api.unlocked) return;
    try {
      var u = new SpeechSynthesisUtterance(' ');
      u.volume = 0;
      synth.speak(u);
      api.unlocked = true;
    } catch (e) {}
    refresh();
  };
  api.speak = function (text, name, lang, rate, volume) {
    try {
      synth.cancel();
      var u = new SpeechSynthesisUtterance(text);
      var vs = synth.getVoices();
      for (var i = 0; i < vs.length; i++) { if (vs[i].name === name) { u.voice = vs[i]; break; } }
      u.lang = lang || 'af-ZA';
      u.rate = rate;
      u.volume = volume;
      synth.speak(u);
    } catch (e) {}
  };
  // Safari only allows speech that starts inside a real user-gesture handler, and Godot
  // handles input a frame later. Unlock on the first DOM tap/click/key instead.
  var evs = ['touchend', 'pointerup', 'mouseup', 'click', 'keydown'];
  function onGesture() {
    api.unlock();
    evs.forEach(function (t) { document.removeEventListener(t, onGesture, true); });
  }
  evs.forEach(function (t) { document.addEventListener(t, onGesture, true); });
  try { synth.addEventListener('voiceschanged', refresh); } catch (e) { synth.onvoiceschanged = refresh; }
  refresh();
  window.__bokspringSpeech = api;
  return true;
})();
"""


func _js_install() -> bool:
	var ok = _js_eval(_JS_SETUP)
	if ok != true:
		_errors.append("JavaScriptBridge unavailable or no speechSynthesis in this browser")
		return false
	return true


func _js_eval(code: String) -> Variant:
	if not _is_web:
		return null
	if not ClassDB.class_exists("JavaScriptBridge") and not Engine.has_singleton("JavaScriptBridge"):
		return null
	return JavaScriptBridge.eval(code, true)


## A JS string literal for `s` (JSON is valid JS once U+2028/2029 are escaped).
func _js_str(s: String) -> String:
	return JSON.stringify(s).replace("\u2028", "\\u2028").replace("\u2029", "\\u2029")
