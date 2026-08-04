extends Node

## In-engine per-NPC memory + relationships for LOCAL / RULE_BASED modes.
## JSON-backed (Godot has no built-in SQLite), mirroring the Python MemoryStore API shape.
## Recall ranks by keyword overlap and recency — no embeddings (see NobodyWhoEncoder for a future upgrade).

const SAVE_PATH := "user://local_memory.json"
const MAX_PER_NPC := 200

# npc_id -> Array[{ "text": String, "meta": Dictionary, "t": int }]
var _memories: Dictionary = {}
# "a|b" (sorted) -> float score in [-1, 1]
var _relationships: Dictionary = {}

const _SEED_RELATIONSHIPS := [
	["alex", "jordan", 0.6],
	["alex", "sam", 0.3],
	["jordan", "riley", 0.7],
	["sam", "morgan", 0.5],
	["riley", "casey", 0.4],
	["morgan", "casey", 0.8],
	["alex", "morgan", -0.2],
]


func _ready() -> void:
	_seed_relationships()
	_load()


func _seed_relationships() -> void:
	for pair in _SEED_RELATIONSHIPS:
		_relationships[_rel_key(pair[0], pair[1])] = float(pair[2])


func record(npc_id: String, text: String, meta: Dictionary = {}) -> void:
	if not _memories.has(npc_id):
		_memories[npc_id] = []
	var entries: Array = _memories[npc_id]
	entries.append({"text": text, "meta": meta, "t": Time.get_unix_time_from_system()})
	if entries.size() > MAX_PER_NPC:
		entries.remove_at(0)
	_save()


func recall(npc_id: String, query: String, top_k: int = 5) -> Array:
	var entries: Array = _memories.get(npc_id, [])
	if entries.is_empty():
		return []
	var terms := _tokenize(query)
	var newest: float = float(entries[entries.size() - 1]["t"])
	var oldest: float = float(entries[0]["t"])
	var span: float = maxf(1.0, newest - oldest)

	var scored: Array = []
	for entry in entries:
		var overlap := 0
		var entry_terms := _tokenize(str(entry["text"]))
		for term in terms:
			if term in entry_terms:
				overlap += 1
		var recency: float = (float(entry["t"]) - oldest) / span  # 0..1, newer is higher
		var score: float = float(overlap) + recency * 0.5
		scored.append({"score": score, "text": str(entry["text"])})

	scored.sort_custom(func(a, b): return a["score"] > b["score"])
	var result: Array = []
	for i in range(mini(top_k, scored.size())):
		result.append(scored[i]["text"])
	return result


func update_relationship(from_npc: String, to_npc: String, delta: float) -> float:
	var key := _rel_key(from_npc, to_npc)
	var new_score: float = clampf(float(_relationships.get(key, 0.0)) + delta, -1.0, 1.0)
	_relationships[key] = new_score
	_save()
	return new_score


func get_relationships() -> Array:
	var entries: Array = []
	for key in _relationships:
		var parts: PackedStringArray = key.split("|")
		var score: float = float(_relationships[key])
		var label := "friend" if score > 0.5 else "rival" if score < -0.1 else "neutral"
		entries.append({"from_npc": parts[0], "to_npc": parts[1], "score": score, "label": label})
	return entries


func clear() -> void:
	_memories.clear()
	_relationships.clear()
	_seed_relationships()
	_save()


func _rel_key(a: String, b: String) -> String:
	var pair := [a.to_lower(), b.to_lower()]
	pair.sort()
	return "%s|%s" % [pair[0], pair[1]]


func _tokenize(text: String) -> PackedStringArray:
	var cleaned := text.to_lower()
	for ch in [".", ",", "!", "?", ":", ";", "\"", "'", "(", ")"]:
		cleaned = cleaned.replace(ch, " ")
	var tokens := PackedStringArray()
	for word in cleaned.split(" ", false):
		if word.length() > 2:
			tokens.append(word)
	return tokens


func _save() -> void:
	var data := {"memories": _memories, "relationships": _relationships}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))


func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_memories = parsed.get("memories", {})
		# Overlay persisted relationship scores onto the seeded defaults.
		var saved_rels: Dictionary = parsed.get("relationships", {})
		for key in saved_rels:
			_relationships[key] = float(saved_rels[key])
