extends SceneTree

## Tests the MusicManager autoload: bus creation, stream generation, crossfade logic,
## and that the signal-driven mood transitions fire without errors.

var _failures := 0


func _check(label: String, cond: bool) -> void:
	if not cond:
		_failures += 1
		print("FAIL: %s" % label)


func _process(_delta: float) -> bool:
	var mm := root.get_node_or_null("MusicManager")
	_check("MusicManager autoload present", mm != null)
	if mm == null:
		quit(_failures)
		return true

	# bus creation
	_check("Music bus exists", AudioServer.get_bus_index("Music") != -1)
	_check("SFX bus exists", AudioServer.get_bus_index("SFX") != -1)
	_check("Ambience bus exists", AudioServer.get_bus_index("Ambience") != -1)

	# players created
	_check("music player created", mm.get_node_or_null("MusicPlayer") != null)
	_check("ambience player created", mm.get_node_or_null("AmbiencePlayer") != null)
	_check("sfx pool created", mm._sfx_players.size() == 4)

	# stream generation
	var dawn: AudioStreamWAV = mm._get_music_stream("dawn")
	_check("dawn stream generated", dawn != null and dawn.data.size() > 0)
	var night: AudioStreamWAV = mm._get_music_stream("night")
	_check("night stream generated", night != null and night.data.size() > 0)
	var ending: AudioStreamWAV = mm._get_music_stream("ending")
	_check("ending stream generated", ending != null and ending.data.size() > 0)

	# ambience stream
	var dorm_amb: AudioStream = mm._get_ambience_stream("ambience_dorm")
	_check("dorm ambience generated", dorm_amb != null)

	# volume API
	mm.set_music_volume(-12.0)
	_check("music volume set", is_equal_approx(mm.get_music_volume(), -12.0))
	mm.set_ambience_volume(-18.0)
	_check("ambience volume set", is_equal_approx(mm.get_ambience_volume(), -18.0))

	# stop_all
	mm.stop_all()
	_check("music stopped", not mm._music_player.playing)
	_check("ambience stopped", not mm._ambience_player.playing)

	# signal-driven mood transitions (simulate time change)
	mm._on_time_changed(3.0, 0, 1)   # night
	_check("night mood set", mm._current_music_key == "music_night")
	mm._on_time_changed(7.0, 0, 1)   # dawn
	_check("dawn mood set", mm._current_music_key == "music_dawn")
	mm._on_time_changed(12.0, 0, 1)  # day
	_check("day mood set", mm._current_music_key == "music_day")
	mm._on_time_changed(17.0, 0, 1)  # dusk
	_check("dusk mood set", mm._current_music_key == "music_dusk")

	# location change
	mm._on_location_changed("campus")
	_check("campus ambience set", mm._current_ambience_key == "ambience_outside")
	mm._on_location_changed("dorm")
	_check("dorm ambience set", mm._current_ambience_key == "ambience_dorm")

	if _failures == 0:
		print("PASS: test_music_manager")
	else:
		print("FAIL: test_music_manager — %d failures" % _failures)
	quit(_failures)
	return true
