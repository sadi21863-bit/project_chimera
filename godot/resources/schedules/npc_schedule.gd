extends Resource
class_name NpcSchedule

@export var npc_id: String = ""
@export var entries: Array[ScheduleEntry] = []


func get_entry_for_hour(hour: float) -> ScheduleEntry:
	for entry in entries:
		if entry.contains_hour(hour):
			return entry
	if entries.is_empty():
		return null
	return entries[0]
