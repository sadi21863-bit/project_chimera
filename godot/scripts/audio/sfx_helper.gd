extends Node

## Thin convenience layer over procedural SFX generation + MusicManager.
## SFXHelper.play(category) without worrying about generation details.

var _gen = null

# Category constants (matches SFXData.Category enum)
const CLUE_FOUND := 0
const INTERROGATION_START := 1
const PRESSURE_INCREASE := 2
const SUSPICION := 3
const TRAVEL := 4
const SEARCH := 5
const ACCUSE := 6
const ENDING := 7

func _ready() -> void:
	var sfx_script = load("res://scripts/audio/procedural_sfx.gd")
	if sfx_script:
		_gen = sfx_script.new()


func play(category: int, volume_db: float = 0.0) -> void:
	if _gen == null:
		return
	var stream: AudioStream = _gen.generate(category)
	if stream == null:
		return
	var mm := _get_music_manager()
	if mm != null:
		mm.play_sfx(stream, volume_db)


func play_raw(freq_hz: float, amp: float, dur: float,
		waveform: String = "sine", volume_db: float = 0.0) -> void:
	if _gen == null:
		return
	var stream: AudioStream = _gen.generate_raw(freq_hz, amp, dur, waveform)
	var mm := _get_music_manager()
	if mm != null:
		mm.play_sfx(stream, volume_db)


func clue_found() -> void:
	play(CLUE_FOUND)


func interrogation_start() -> void:
	play(INTERROGATION_START)


func pressure_increase() -> void:
	play(PRESSURE_INCREASE)


func suspicion() -> void:
	play(SUSPICION, -3.0)


func travel() -> void:
	play(TRAVEL)


func search() -> void:
	play(SEARCH)


func accuse() -> void:
	play(ACCUSE, 3.0)


## Accusation-reveal sting for the accusation_reveal panel (same voice as accuse).
func accusation_reveal() -> void:
	play(ACCUSE, 3.0)


func ending() -> void:
	play(ENDING, -2.0)


func _get_music_manager() -> Node:
	return get_node_or_null("/root/MusicManager")
