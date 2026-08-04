from __future__ import annotations

from enum import Enum
from typing import Any

from pydantic import BaseModel, Field


class ActionType(str, Enum):
    MOVE = "move"
    SPEAK = "speak"
    IDLE = "idle"
    INTERACT = "interact"


class NpcAction(BaseModel):
    action: ActionType = ActionType.IDLE
    target_room: str | None = None
    target_npc: str | None = None
    text: str | None = None
    interact_object: str | None = None
    reason: str | None = None


class NearbyNpc(BaseModel):
    id: str
    name: str
    room: str
    distance: float = 0.0


class NpcContext(BaseModel):
    npc_id: str
    name: str
    personality: str = ""
    current_room: str = "hallway"
    schedule_goal: str = ""
    nearby_npcs: list[NearbyNpc] = Field(default_factory=list)
    recent_events: list[str] = Field(default_factory=list)
    game_hour: float = 8.0
    game_day: int = 1
    secrets: list[str] = Field(default_factory=list)


class DecideRequest(BaseModel):
    context: NpcContext


class DecideResponse(BaseModel):
    action: NpcAction
    source: str = "game_master"
    memories_used: list[str] = Field(default_factory=list)


class MemoryRecord(BaseModel):
    npc_id: str
    text: str
    event_type: str = "observation"
    metadata: dict[str, Any] = Field(default_factory=dict)


class MemoryRecallRequest(BaseModel):
    npc_id: str
    query: str
    top_k: int = 5


class MemoryRecallResponse(BaseModel):
    memories: list[str]


class EventInjectRequest(BaseModel):
    text: str
    severity: str = "normal"
    target_room: str | None = None


class RelationshipEntry(BaseModel):
    from_npc: str
    to_npc: str
    score: float
    label: str = "neutral"


class RelationshipsResponse(BaseModel):
    relationships: list[RelationshipEntry]


class BatchDecideRequest(BaseModel):
    contexts: list[NpcContext]


class BatchDecideResponse(BaseModel):
    decisions: list[DecideResponse]
