extends Resource
class_name NpcProfile

@export var npc_id: String = ""
@export var display_name: String = ""
@export var personality: String = ""
@export var bedroom: String = "bedroom_1"
@export var color: Color = Color.WHITE
@export var secrets: PackedStringArray = []
@export var relationship_seeds: Dictionary = {}
@export var schedule: NpcSchedule
@export var sprite_frames: SpriteFrames
