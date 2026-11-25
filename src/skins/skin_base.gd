class_name SkinBase
extends Node
## Interface every game skin implements. A skin asks the engine for the next
## challenge, renders it, and reports the result. A new skin only needs to
## extend this class: no changes to src/engine/.
##
##   start(engine, host)  - begin playing; host gives speech, sound and saving
##   on_challenge(c)      - show one challenge (see challenge_gen.gd for the format)
##   on_end(summary)      - the round is over (engine.round_summary())

signal round_finished(summary: Dictionary)
signal exit_requested

var engine: LearningEngine
## The app shell. Provides: speak(text), play_sfx(name), save(), settings (Dictionary).
var host: Node


func start(p_engine: LearningEngine, p_host: Node) -> void:
	engine = p_engine
	host = p_host


func on_challenge(_c: Dictionary) -> void:
	pass


func on_end(summary: Dictionary) -> void:
	round_finished.emit(summary)


## Asks the engine for the next challenge and calls on_challenge or on_end.
func request_challenge() -> void:
	var c := engine.next_challenge()
	if c.is_empty():
		on_end(engine.round_summary())
	else:
		on_challenge(c)


## Reports a result to the engine and saves progress.
func report(c: Dictionary, correct: bool, response_ms: int) -> Dictionary:
	var r := engine.report_result(str(c.itemId), correct, response_ms)
	if host and host.has_method("save"):
		host.save()
	return r
