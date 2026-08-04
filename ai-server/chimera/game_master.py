from __future__ import annotations

import logging

from chimera.llm import generate_action
from chimera.memory import MemoryStore
from chimera.models import (
    ActionType,
    DecideRequest,
    DecideResponse,
    EventInjectRequest,
    MemoryRecord,
    MemoryRecallRequest,
    MemoryRecallResponse,
    NpcAction,
    NpcContext,
    RelationshipsResponse,
    RelationshipEntry,
)

logger = logging.getLogger(__name__)

VALID_ROOMS = {
    "bedroom_1",
    "bedroom_2",
    "bedroom_3",
    "bedroom_4",
    "bedroom_5",
    "bedroom_6",
    "common_room",
    "kitchen",
    "bathroom",
    "hallway",
}

VALID_NPCS = {"alex", "jordan", "sam", "riley", "morgan", "casey"}

_injected_events: list[str] = []


class GameMaster:
    def __init__(self, memory: MemoryStore) -> None:
        self.memory = memory

    def inject_event(self, request: EventInjectRequest) -> dict:
        msg = f"[{request.severity}] {request.text}"
        if request.target_room:
            msg += f" (room: {request.target_room})"
        _injected_events.append(msg)
        if len(_injected_events) > 50:
            _injected_events.pop(0)
        for npc in VALID_NPCS:
            self.memory.record(npc, msg, {"event_type": "injected"})
        return {"status": "ok", "event": msg}

    def validate_action(self, action: NpcAction, context: NpcContext) -> NpcAction:
        if action.action == ActionType.MOVE:
            if not action.target_room or action.target_room not in VALID_ROOMS:
                return NpcAction(action=ActionType.IDLE, reason="invalid room rejected")
            if action.target_room == context.current_room:
                return NpcAction(action=ActionType.IDLE, reason="already in target room")

        if action.action == ActionType.SPEAK:
            if not action.target_npc or action.target_npc.lower() not in VALID_NPCS:
                return NpcAction(action=ActionType.IDLE, reason="invalid speak target")
            if not action.text:
                action.text = "..."

        if action.action == ActionType.INTERACT:
            if not action.interact_object:
                return NpcAction(action=ActionType.IDLE, reason="missing interact target")

        return action

    async def decide(self, request: DecideRequest) -> DecideResponse:
        ctx = request.context
        query = f"{ctx.schedule_goal} {ctx.current_room} {' '.join(ctx.recent_events[-3:])}"
        for event in _injected_events[-3:]:
            ctx.recent_events.append(event)
        memories = self.memory.recall(ctx.npc_id, query, top_k=5)
        raw_action, source = await generate_action(ctx, memories)
        validated = self.validate_action(raw_action, ctx)

        if validated.action == ActionType.SPEAK and validated.target_npc:
            self.memory.record(
                ctx.npc_id,
                f"Said to {validated.target_npc}: {validated.text}",
                {"event_type": "dialogue"},
            )
            self.memory.update_relationship(ctx.npc_id, validated.target_npc, 0.05)

        if validated.action == ActionType.MOVE and validated.target_room:
            self.memory.record(
                ctx.npc_id,
                f"Moved toward {validated.target_room} because: {validated.reason or 'unknown'}",
                {"event_type": "movement"},
            )

        return DecideResponse(action=validated, source=source, memories_used=memories)

    def record_memory(self, record: MemoryRecord) -> dict:
        doc_id = self.memory.record(record.npc_id, record.text, record.metadata)
        return {"status": "ok", "id": doc_id}

    def recall_memory(self, request: MemoryRecallRequest) -> MemoryRecallResponse:
        memories = self.memory.recall(request.npc_id, request.query, request.top_k)
        return MemoryRecallResponse(memories=memories)

    def get_relationships(self) -> RelationshipsResponse:
        entries = [
            RelationshipEntry(**e) for e in self.memory.get_relationships()
        ]
        return RelationshipsResponse(relationships=entries)
