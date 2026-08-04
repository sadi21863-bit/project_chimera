extends Node

## In-game clock with pause and speed multiplier.
## 1 real second = 1 game minute at 1x speed.

signal time_changed(hour: float, minute: int, day: int)
signal paused_changed(is_paused: bool)
signal speed_changed(multiplier: float)

const MINUTES_PER_DAY := 1440
const START_HOUR := 7.0

var game_day: int = 1
var game_minute: float = START_HOUR * 60.0
var speed_multiplier: float = 1.0
var is_paused: bool = false

var _accumulator: float = 0.0


func _ready() -> void:
	set_process(true)


func _process(delta: float) -> void:
	if is_paused:
		return
	_accumulator += delta * speed_multiplier
	while _accumulator >= 1.0:
		_accumulator -= 1.0
		_advance_minute()


func _advance_minute() -> void:
	game_minute += 1.0
	if game_minute >= MINUTES_PER_DAY:
		game_minute = 0.0
		game_day += 1
	time_changed.emit(get_hour(), get_minute_int(), game_day)


func get_hour() -> float:
	return game_minute / 60.0


func get_minute_int() -> int:
	return int(game_minute) % 60


func get_time_string() -> String:
	var h := int(get_hour())
	var m := get_minute_int()
	return "%02d:%02d Day %d" % [h, m, game_day]


func get_day_phase() -> float:
	return get_hour() / 24.0


func play() -> void:
	is_paused = false
	paused_changed.emit(false)


func pause() -> void:
	is_paused = true
	paused_changed.emit(true)


func toggle_pause() -> void:
	if is_paused:
		play()
	else:
		pause()


func set_speed(multiplier: float) -> void:
	speed_multiplier = clampf(multiplier, 0.25, 8.0)
	speed_changed.emit(speed_multiplier)


func set_time(hour: float, day: int = -1) -> void:
	game_minute = hour * 60.0
	if day >= 0:
		game_day = day
	time_changed.emit(get_hour(), get_minute_int(), game_day)


func advance_hours(h: float) -> void:
	var total: float = get_hour() + h
	var day_gain: int = int(total) / 24
	var new_hour: float = fmod(total, 24.0)
	set_time(new_hour, game_day + day_gain)


func advance_days(n: int) -> void:
	set_time(get_hour(), game_day + n)


func get_save_data() -> Dictionary:
	return {
		"game_day": game_day,
		"game_minute": game_minute,
		"speed_multiplier": speed_multiplier,
		"is_paused": is_paused,
	}


func load_save_data(data: Dictionary) -> void:
	game_day = int(data.get("game_day", 1))
	game_minute = float(data.get("game_minute", START_HOUR * 60.0))
	speed_multiplier = float(data.get("speed_multiplier", 1.0))
	is_paused = bool(data.get("is_paused", false))
	time_changed.emit(get_hour(), get_minute_int(), game_day)
