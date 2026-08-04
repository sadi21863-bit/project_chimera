extends Node

## Which places exist and where the detective currently is. Travelling advances time.

const LOCATIONS := {
	"dorm": {"name": "Crestwood Hall", "scene": "res://scenes/dorm/crestwood_hall.tscn", "travel_hours": 0.0},
	"detective_room": {"name": "Your Room", "scene": "res://scenes/locations/detective_room.tscn", "travel_hours": 1.0},
	"police_station": {"name": "Police Station", "scene": "res://scenes/locations/police_station.tscn", "travel_hours": 1.0},
	"university": {"name": "University", "scene": "res://scenes/locations/university.tscn", "travel_hours": 1.0},
	"bedroom_1": {"name": "Alex's Room", "scene": "res://scenes/dorm/bedroom_1.tscn", "travel_hours": 0.0},
	"bedroom_2": {"name": "Jordan's Room", "scene": "res://scenes/dorm/bedroom_2.tscn", "travel_hours": 0.0},
	"bedroom_3": {"name": "Sam's Room", "scene": "res://scenes/dorm/bedroom_3.tscn", "travel_hours": 0.0},
	"bedroom_4": {"name": "Riley's Room", "scene": "res://scenes/dorm/bedroom_4.tscn", "travel_hours": 0.0},
	"bedroom_5": {"name": "Morgan's Room", "scene": "res://scenes/dorm/bedroom_5.tscn", "travel_hours": 0.0},
	"bedroom_6": {"name": "Casey's Room", "scene": "res://scenes/dorm/bedroom_6.tscn", "travel_hours": 0.0},
	"daniel_room": {"name": "Daniel's Room", "scene": "res://scenes/dorm/daniel_room.tscn", "travel_hours": 0.0},
	"campus": {"name": "The Campus", "scene": "res://scenes/locations/campus.tscn", "travel_hours": 0.0},
}

signal location_changing(dest_id: String)

var current_id := "dorm"
var visited: Dictionary = {"dorm": true}
var _scheduler: Node = null


func _ready() -> void:
	_scheduler = get_node_or_null("/root/Scheduler")


func travel(dest_id: String) -> bool:
	if not LOCATIONS.has(dest_id) or dest_id == current_id:
		return false
	var hours: float = float(LOCATIONS[dest_id]["travel_hours"])
	if _scheduler != null and hours > 0.0:
		_scheduler.advance_hours(hours)
	current_id = dest_id
	visited[dest_id] = true
	location_changing.emit(dest_id)
	return true


func is_unvisited(id: String) -> bool:
	return not visited.get(id, false)


func location_name(id: String) -> String:
	return str(LOCATIONS[id]["name"]) if LOCATIONS.has(id) else id


func location_scene(id: String) -> String:
	return str(LOCATIONS[id]["scene"]) if LOCATIONS.has(id) else ""


func get_save_data() -> Dictionary:
	return {"current_id": current_id, "visited": visited.duplicate(true)}


func load_save_data(data: Dictionary) -> void:
	current_id = str(data.get("current_id", "dorm"))
	var raw_visited: Variant = data.get("visited", {"dorm": true})
	visited = raw_visited if raw_visited is Dictionary else {"dorm": true}
	location_changing.emit(current_id)
