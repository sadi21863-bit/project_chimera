extends CharacterBody2D
class_name DormNpc

@export var profile: NpcProfile

const FOOTSTEP_INTERVAL := 0.4
const ROOM_FOOTSTEP_SOUNDS := {
	"kitchen": ["ceramic_00", "ceramic_01", "ceramic_02"],
	"bathroom": ["ceramic_00", "ceramic_01", "ceramic_02"],
	"hallway": ["linoleum_00", "linoleum_01", "linoleum_02"],
	"common_room": ["linoleum_00", "linoleum_01", "linoleum_02"],
}
const DEFAULT_FOOTSTEP_SOUNDS := ["carpet_00", "carpet_01", "carpet_02"]

var npc_id: String = ""
var display_name: String = ""
var current_room: String = "hallway"
var current_activity: String = ""

var _nav: NavigationAgent2D
var _sprite: AnimatedSprite2D
var _label: Label
var _footstep_player: AudioStreamPlayer2D
var _footstep_timer := 0.0
var _room_markers: Dictionary = {}
var _all_npcs: Array = []
var _navigating := false
var _action_running := false
var _speed := 80.0


func _ready() -> void:
	_nav = $NavigationAgent2D
	_sprite = $Sprite
	_label = $Label
	_footstep_player = $FootstepPlayer
	if profile:
		_apply_profile(profile)
	add_to_group("npcs")
	Scheduler.time_changed.connect(_on_time_changed)
	call_deferred("_setup_navigation")


func setup(profile_data: NpcProfile, markers: Dictionary, npcs: Array) -> void:
	profile = profile_data
	_room_markers = markers
	_all_npcs = npcs
	_apply_profile(profile_data)


func _apply_profile(p: NpcProfile) -> void:
	npc_id = p.npc_id
	display_name = p.display_name
	if p.sprite_frames:
		_sprite.sprite_frames = p.sprite_frames
		_sprite.play("idle_down")
	_label.text = display_name
	current_room = p.bedroom
	global_position = _get_marker_position(p.bedroom)
	_on_time_changed(Scheduler.get_hour(), Scheduler.get_minute_int(), Scheduler.game_day)


func _setup_navigation() -> void:
	await get_tree().physics_frame
	_nav.target_desired_distance = 4.0
	_nav.path_desired_distance = 4.0


func _physics_process(delta: float) -> void:
	if not _navigating or Scheduler.is_paused:
		return
	if _nav.is_navigation_finished():
		_navigating = false
		velocity = Vector2.ZERO
		if _sprite.sprite_frames:
			_sprite.play("idle_down")
		return
	var next_pos := _nav.get_next_path_position()
	var direction := global_position.direction_to(next_pos)
	velocity = direction * _speed
	move_and_slide()
	_update_footsteps(delta)
	_update_facing(direction)


func _update_facing(direction: Vector2) -> void:
	if not _sprite.sprite_frames:
		return
	var anim: String
	if absf(direction.x) > absf(direction.y):
		anim = "walk_right" if direction.x > 0.0 else "walk_left"
	else:
		anim = "walk_down" if direction.y > 0.0 else "walk_up"
	if _sprite.animation != anim:
		_sprite.play(anim)


func _update_footsteps(delta: float) -> void:
	_footstep_timer -= delta
	if _footstep_timer > 0.0:
		return
	_footstep_timer = FOOTSTEP_INTERVAL
	_play_footstep()


func _play_footstep() -> void:
	var variants: Array = ROOM_FOOTSTEP_SOUNDS.get(current_room, DEFAULT_FOOTSTEP_SOUNDS)
	var variant: String = variants[randi() % variants.size()]
	var path := "res://assets/audio/footstep_%s.ogg" % variant
	if not ResourceLoader.exists(path):
		return
	_footstep_player.stream = load(path)
	_footstep_player.pitch_scale = randf_range(0.92, 1.08)
	_footstep_player.play()


func _on_time_changed(hour: float, _minute: int, _day: int) -> void:
	if profile == null or profile.schedule == null:
		return
	var entry := profile.schedule.get_entry_for_hour(hour)
	if entry:
		current_activity = entry.activity
		var tree: BehaviorTree = $BehaviorTree
		if tree:
			tree.get_blackboard().set_value("schedule_target_room", entry.target_room)


func move_to_room(room_id: String) -> void:
	if not _room_markers.has(room_id):
		EventLog.log_action("%s: unknown room %s" % [display_name, room_id], "error", npc_id)
		return
	var target: Marker2D = _room_markers[room_id]
	_nav.target_position = target.global_position
	_navigating = true
	EventLog.log_action("%s moving to %s" % [display_name, room_id], "movement", npc_id)


func is_navigating() -> bool:
	return _navigating


func is_action_running() -> bool:
	return _action_running


func _get_marker_position(room_id: String) -> Vector2:
	if _room_markers.has(room_id):
		return _room_markers[room_id].global_position
	return global_position


func build_ai_context() -> Dictionary:
	var nearby := _get_nearby_npcs()
	var nearby_data: Array = []
	for n in nearby:
		nearby_data.append({
			"id": n.npc_id,
			"name": n.display_name,
			"room": n.current_room,
			"distance": global_position.distance_to(n.global_position),
		})
	return {
		"npc_id": npc_id,
		"name": display_name,
		"personality": profile.personality if profile else "",
		"current_room": current_room,
		"schedule_goal": "%s in %s" % [current_activity, blackboard_target()],
		"nearby_npcs": nearby_data,
		"recent_events": EventLog.get_filtered(npc_id).slice(-5),
		"game_hour": Scheduler.get_hour(),
		"game_day": Scheduler.game_day,
		"secrets": profile.secrets if profile else [],
	}


func blackboard_target() -> String:
	var tree: BehaviorTree = $BehaviorTree
	if tree:
		return str(tree.get_blackboard().get_value("schedule_target_room", current_room))
	return current_room


func execute_action(action: Dictionary) -> void:
	_action_running = true
	var action_type: String = str(action.get("action", "idle"))

	match action_type:
		"move":
			var room: String = str(action.get("target_room", ""))
			if not room.is_empty():
				move_to_room(room)
				await _wait_for_navigation()
				current_room = room
				EventLog.log_action("%s decided to move to %s" % [display_name, room], "ai", npc_id)
				AIClient.record_memory(npc_id, "Moved to %s: %s" % [room, action.get("reason", "")])
		"speak":
			var target_id: String = str(action.get("target_npc", ""))
			var text: String = str(action.get("text", "..."))
			var target := _find_npc(target_id)
			var target_name := target.display_name if target else target_id
			DialogSystem.show_dialogue(display_name, text)
			EventLog.log_action('%s says to %s: "%s"' % [display_name, target_name, text], "dialogue", npc_id)
			AIClient.record_memory(npc_id, "Said to %s: %s" % [target_name, text])
			EventBus.emit_event("relationship_changed", {
				"from": npc_id, "to": target_id, "delta": 0.05
			})
			await get_tree().create_timer(3.0).timeout
		"interact":
			var obj: String = str(action.get("interact_object", "object"))
			EventLog.log_action("%s interacts with %s" % [display_name, obj], "ai", npc_id)
			await get_tree().create_timer(2.0).timeout
		_:
			await get_tree().create_timer(1.0).timeout

	_action_running = false


func _wait_for_navigation() -> void:
	while _navigating:
		await get_tree().process_frame


func _get_nearby_npcs() -> Array:
	var result: Array = []
	for n in _all_npcs:
		if n != self and global_position.distance_to(n.global_position) < 120.0:
			result.append(n)
	return result


func _find_npc(id: String) -> DormNpc:
	for n in _all_npcs:
		if n.npc_id == id:
			return n
	return null


func get_save_data() -> Dictionary:
	var schedule_target: String = current_room
	if has_node("BehaviorTree"):
		var tree: BehaviorTree = get_node("BehaviorTree")
		schedule_target = str(tree.get_blackboard().get_value("schedule_target_room", current_room))
	return {
		"npc_id": npc_id,
		"position": {"x": global_position.x, "y": global_position.y},
		"current_room": current_room,
		"current_activity": current_activity,
		"schedule_target_room": schedule_target,
	}


func load_save_data(data: Dictionary) -> void:
	if data.has("position"):
		var pos: Dictionary = data["position"]
		global_position = Vector2(pos.get("x", 0.0), pos.get("y", 0.0))
	current_room = str(data.get("current_room", current_room))
	current_activity = str(data.get("current_activity", ""))
	if has_node("BehaviorTree"):
		var tree: BehaviorTree = get_node("BehaviorTree")
		var target: String = str(data.get("schedule_target_room", current_room))
		tree.get_blackboard().set_value("schedule_target_room", target)
