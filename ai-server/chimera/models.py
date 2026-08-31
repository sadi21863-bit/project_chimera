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
    npc_id: str = Field(..., min_length=1, max_length=50)
    name: str = Field(..., min_length=1, max_length=100)
    personality: str = Field(default="", max_length=500)
    current_room: str = Field(default="hallway", max_length=50)
    schedule_goal: str = Field(default="", max_length=200)
    nearby_npcs: list[NearbyNpc] = Field(default_factory=list)
    recent_events: list[str] = Field(default_factory=list)
    game_hour: float = Field(default=8.0, ge=0.0, le=24.0)
    game_day: int = Field(default=1, ge=1, le=365)
    secrets: list[str] = Field(default_factory=list)


class DecideRequest(BaseModel):
    context: NpcContext


class DecideResponse(BaseModel):
    action: NpcAction
    source: str = "game_master"
    memories_used: list[str] = Field(default_factory=list)


class MemoryRecord(BaseModel):
    npc_id: str = Field(..., min_length=1, max_length=50)
    text: str = Field(..., min_length=1, max_length=2000)
    event_type: str = Field(default="observation", max_length=50)
    metadata: dict[str, Any] = Field(default_factory=dict)


class MemoryRecallRequest(BaseModel):
    npc_id: str = Field(..., min_length=1, max_length=50)
    query: str = Field(..., min_length=1, max_length=500)
    top_k: int = Field(default=5, ge=1, le=20)


class MemoryRecallResponse(BaseModel):
    memories: list[str]


class EventInjectRequest(BaseModel):
    text: str = Field(..., min_length=1, max_length=500)
    severity: str = Field(default="normal", max_length=20)
    target_room: str | None = Field(default=None, max_length=50)


class RelationshipEntry(BaseModel):
    from_npc: str
    to_npc: str
    score: float = Field(..., ge=-1.0, le=1.0)
    label: str = "neutral"


class RelationshipsResponse(BaseModel):
    relationships: list[RelationshipEntry]


class BatchDecideRequest(BaseModel):
    contexts: list[NpcContext] = Field(..., min_length=1, max_length=10)


class BatchDecideResponse(BaseModel):
    decisions: list[DecideResponse]
