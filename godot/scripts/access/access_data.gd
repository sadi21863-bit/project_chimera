extends RefCounted
class_name AccessData

## Time-gated + owned areas. Common spaces are public and always open; each bedroom belongs to a
## suspect and is off-limits outside its open window unless that suspect is present to let you in.

const AREAS := {
	"kitchen": {"open_hour": 0.0, "close_hour": 24.0, "owner": ""},
	"common_room": {"open_hour": 0.0, "close_hour": 24.0, "owner": ""},
	"hallway": {"open_hour": 0.0, "close_hour": 24.0, "owner": ""},
	"bathroom": {"open_hour": 0.0, "close_hour": 24.0, "owner": ""},
	"bedroom_1": {"open_hour": 8.0, "close_hour": 22.0, "owner": "alex"},
	"bedroom_2": {"open_hour": 8.0, "close_hour": 22.0, "owner": "jordan"},
	"bedroom_3": {"open_hour": 8.0, "close_hour": 22.0, "owner": "sam"},
	"bedroom_4": {"open_hour": 8.0, "close_hour": 22.0, "owner": "riley"},
	"bedroom_5": {"open_hour": 8.0, "close_hour": 22.0, "owner": "morgan"},
	"bedroom_6": {"open_hour": 8.0, "close_hour": 22.0, "owner": "casey"},
}


static func area(area_id: String) -> Dictionary:
	return AREAS.get(area_id, {})


static func is_restricted(area_id: String, hour: float, owner_present: bool) -> bool:
	if owner_present:
		return false
	var a: Dictionary = AREAS.get(area_id, {})
	if a.is_empty():
		return false
	return hour < float(a["open_hour"]) or hour >= float(a["close_hour"])
