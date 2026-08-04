"""FastAPI entry point for Project Chimera AI server."""

from __future__ import annotations

import logging

import uvicorn
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from chimera.game_master import GameMaster
from chimera.memory import MemoryStore
from chimera.models import (
    BatchDecideRequest,
    BatchDecideResponse,
    DecideRequest,
    DecideResponse,
    EventInjectRequest,
    MemoryRecord,
    MemoryRecallRequest,
    MemoryRecallResponse,
    RelationshipsResponse,
)

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="Project Chimera AI Server", version="0.1.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

memory_store = MemoryStore()
game_master = GameMaster(memory_store)


@app.get("/health")
async def health() -> dict:
    return {
        "status": "ok",
        "service": "chimera-ai-server",
        "chroma_path": memory_store.snapshot_path(),
    }


@app.post("/npc/decide", response_model=DecideResponse)
async def npc_decide(request: DecideRequest) -> DecideResponse:
    return await game_master.decide(request)


@app.post("/npc/decide/batch", response_model=BatchDecideResponse)
async def npc_decide_batch(request: BatchDecideRequest) -> BatchDecideResponse:
    decisions = []
    for ctx in request.contexts:
        result = await game_master.decide(DecideRequest(context=ctx))
        decisions.append(result)
    return BatchDecideResponse(decisions=decisions)


@app.post("/memory/record")
async def memory_record(record: MemoryRecord) -> dict:
    return game_master.record_memory(record)


@app.post("/memory/recall", response_model=MemoryRecallResponse)
async def memory_recall(request: MemoryRecallRequest) -> MemoryRecallResponse:
    return game_master.recall_memory(request)


@app.post("/events/inject")
async def events_inject(request: EventInjectRequest) -> dict:
    return game_master.inject_event(request)


@app.get("/relationships", response_model=RelationshipsResponse)
async def relationships() -> RelationshipsResponse:
    return game_master.get_relationships()


def main() -> None:
    logger.info("Starting Chimera AI server on http://localhost:8000")
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=False)


if __name__ == "__main__":
    main()
