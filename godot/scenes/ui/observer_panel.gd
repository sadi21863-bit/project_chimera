extends Control

## Observer dashboard: speed, event log, injection, relationships, NPC info.

@onready var _time_label: Label = $Margin/VBox/TopBar/TimeLabel
@onready var _status_label: Label = $Margin/VBox/TopBar/StatusLabel
@onready var _log: RichTextLabel = $Margin/VBox/HSplit/LeftPanel/LogScroll/LogText
@onready var _filter: OptionButton = $Margin/VBox/HSplit/LeftPanel/FilterRow/FilterOption
@onready var _inject_input: LineEdit = $Margin/VBox/HSplit/LeftPanel/InjectRow/InjectInput
@onready var _speed_slider: HSlider = $Margin/VBox/TopBar/SpeedSlider
@onready var _relationship_graph: Control = $Margin/VBox/HSplit/RightPanel/RelationshipGraph
@onready var _npc_info: RichTextLabel = $Margin/VBox/HSplit/RightPanel/NpcInfoPanel/InfoText

var _npcs: Array = []
var _selected_npc: DormNpc = null
var _relationship_refresh := 0.0


func _ready() -> void:
	_filter.add_item("All", 0)
	_speed_slider.min_value = 0.5
	_speed_slider.max_value = 8.0
	_speed_slider.value = 1.0
	_speed_slider.step = 0.5

	Scheduler.time_changed.connect(_on_time_changed)
	Scheduler.paused_changed.connect(_on_paused_changed)
	Scheduler.speed_changed.connect(_on_speed_changed)
	EventLog.entry_added.connect(_refresh_log)
	AIClient.server_status_changed.connect(_on_server_status)
	EventBus.subscribe("relationship_changed", _on_relationship_changed)
	_relationship_graph.node_clicked.connect(select_npc)

	_on_time_changed(Scheduler.get_hour(), Scheduler.get_minute_int(), Scheduler.game_day)
	_refresh_log("", "", "")
	_update_status()


func bind_npcs(npcs: Array) -> void:
	_npcs = npcs
	_filter.clear()
	_filter.add_item("All", 0)
	for npc in npcs:
		_filter.add_item(npc.display_name)
	_relationship_graph.setup(npcs)


func _process(delta: float) -> void:
	_relationship_refresh -= delta
	if _relationship_refresh <= 0.0:
		_relationship_refresh = 10.0
		_fetch_relationships()


func _on_time_changed(_h: float, _m: int, _d: int) -> void:
	_time_label.text = Scheduler.get_time_string()


func _on_paused_changed(paused: bool) -> void:
	_update_status()


func _on_speed_changed(mult: float) -> void:
	_speed_slider.value = mult


func _on_server_status(online: bool) -> void:
	_update_status()


func _update_status() -> void:
	var pause_text := "PAUSED" if Scheduler.is_paused else "RUNNING"
	# Report the effective AI mode (resolve_mode), not server reachability alone: previously
	# a working LOCAL model and the rule-based fallback both rendered as "AI OFF", so the
	# player could not tell a healthy local model from a degraded one. Short labels keep the
	# HBoxContainer top bar inside 1280x720.
	_status_label.text = "%s | AI: %s | %.1fx" % [
		pause_text, AIClient.get_mode_short_label(), Scheduler.speed_multiplier,
	]


func _refresh_log(_text: String, _cat: String, _id: String) -> void:
	var filter_idx := _filter.selected
	var filter_id := ""
	if filter_idx > 0 and filter_idx - 1 < _npcs.size():
		filter_id = _npcs[filter_idx - 1].npc_id
	var lines := EventLog.get_filtered(filter_id if filter_idx > 0 else "all")
	_log.text = "\n".join(lines)


func _on_play_pressed() -> void:
	Scheduler.play()


func _on_pause_pressed() -> void:
	Scheduler.pause()


func _on_speed_slider_changed(value: float) -> void:
	Scheduler.set_speed(value)


func _on_inject_pressed() -> void:
	var text := _inject_input.text.strip_edges()
	if text.is_empty():
		return
	AIClient.inject_event(text)
	_inject_input.text = ""


func _on_save_pressed() -> void:
	var hall := get_tree().root.get_node_or_null("Main/LocationHost/CrestwoodHall")
	var main := get_tree().root.get_node_or_null("Main")
	var data := {
		"scheduler": Scheduler.get_save_data(),
		"event_log": EventLog.get_save_data(),
		"game_flow": GameFlow.get_save_data(),
		"consequences": Consequences.get_save_data(),
		"location_manager": LocationManager.get_save_data(),
		"case_file": CaseFile.get_save_data(),
		"notebook": Notebook.get_save_data(),
	}
	if main != null and main.has_method("get_world_save_data"):
		data["world"] = main.get_world_save_data()
	if hall:
		data["hall"] = hall.get_save_data()
	SaveManager.save_game(SaveManager.DEFAULT_SLOT, data)


func _on_load_pressed() -> void:
	var data := SaveManager.load_game(SaveManager.DEFAULT_SLOT)
	if data.is_empty():
		return
	Scheduler.load_save_data(data.get("scheduler", {}))
	EventLog.load_save_data(data.get("event_log", {}))
	GameFlow.load_save_data(data.get("game_flow", {}))
	Consequences.load_save_data(data.get("consequences", {}))
	LocationManager.load_save_data(data.get("location_manager", {}))
	var main := get_tree().root.get_node_or_null("Main")
	if main != null and main.has_method("load_world_save_data"):
		main.load_world_save_data(data.get("world", {}))
	CaseFile.load_save_data(data.get("case_file", {}))
	Notebook.load_save_data(data.get("notebook", {}))
	var hall := get_tree().root.get_node_or_null("Main/LocationHost/CrestwoodHall")
	if hall and data.has("hall"):
		hall.load_save_data(data["hall"])


func _on_filter_changed(_idx: int) -> void:
	_refresh_log("", "", "")


func _on_relationship_changed(_data: Variant) -> void:
	_fetch_relationships()


func _fetch_relationships() -> void:
	AIClient.fetch_relationships(func(rels):
		_relationship_graph.update_relationships(rels)
	)


func select_npc(npc: DormNpc) -> void:
	_selected_npc = npc
	_show_npc_info(npc)


func _show_npc_info(npc: DormNpc) -> void:
	if npc == null:
		_npc_info.text = "Click an NPC to inspect."
		return
	var info := "[b]%s[/b]\n%s\n\nRoom: %s\nActivity: %s\n\nSecrets: %s" % [
		npc.display_name,
		npc.profile.personality if npc.profile else "",
		npc.current_room,
		npc.current_activity,
		", ".join(npc.profile.secrets) if npc.profile else "",
	]
	_npc_info.text = info
	AIClient.recall_memory(npc.npc_id, npc.current_activity, func(memories):
		if memories.size() > 0:
			_npc_info.text += "\n\n[b]Recent memories:[/b]\n- " + "\n- ".join(memories)
	)
