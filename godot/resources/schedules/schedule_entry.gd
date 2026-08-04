extends Resource
class_name ScheduleEntry

@export var start_hour: float = 7.0
@export var end_hour: float = 9.0
@export var target_room: String = "common_room"
@export var activity: String = "relax"


func contains_hour(hour: float) -> bool:
	if start_hour <= end_hour:
		return hour >= start_hour and hour < end_hour
	return hour >= start_hour or hour < end_hour
