extends Node

## Scrollable action log for simulation events.

signal entry_added(text: String, category: String, npc_id: String)

const MAX_ENTRIES := 200

var entries: Array[Dictionary] = []


func log_action(text: String, category: String = "system", npc_id: String = "") -> void:
	var entry := {
		"text": text,
		"category": category,
		"npc_id": npc_id,
		"time": Scheduler.get_time_string(),
	}
	entries.append(entry)
	if entries.size() > MAX_ENTRIES:
		entries.pop_front()
	entry_added.emit(text, category, npc_id)


func get_filtered(npc_filter: String = "") -> Array[String]:
	var lines: Array[String] = []
	for entry in entries:
		if npc_filter.is_empty() or entry.get("npc_id", "") == npc_filter or npc_filter == "all":
			lines.append("[%s] %s" % [entry.get("time", ""), entry.get("text", "")])
	return lines


func clear_log() -> void:
	entries.clear()
	entry_added.emit("", "clear", "")


func get_save_data() -> Dictionary:
	return {"entries": entries.duplicate(true)}


func load_save_data(data: Dictionary) -> void:
	# data may come straight from JSON.parse_string, which returns an untyped Array — rebuild
	# the typed Array[Dictionary] element by element rather than assigning it directly.
	var raw: Array = data.get("entries", [])
	entries.clear()
	for e in raw:
		if e is Dictionary:
			entries.append(e)
