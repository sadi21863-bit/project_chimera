"""FastAPI entry point for Project Chimera AI server."""

from __future__ import annotations

import logging
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

import uvicorn
from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from chimera.config import get_settings
from chimera.game_master import GameMaster
from chimera.llm import close_http_client
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

memory_store = MemoryStore()
game_master = GameMaster(memory_store)


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    settings = get_settings()
    logger.info(
        "Starting Chimera AI server on http://%s:%d",
        settings.host,
        settings.port,
    )
    yield
    logger.info("Shutting down — flushing ChromaDB…")
    memory_store.persist()
    await close_http_client()
    logger.info("Shutdown complete.")


settings = get_settings()
app = FastAPI(
    title="Project Chimera AI Server",
    version="0.1.0",
    lifespan=lifespan,
    docs_url="/docs" if settings.debug else None,
    redoc_url="/redoc" if settings.debug else None,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)


# ---------------------------------------------------------------------------
# Auth middleware
# ---------------------------------------------------------------------------

@app.middleware("http")
async def auth_middleware(request: Request, call_next):
    settings = get_settings()
    if settings.requires_auth and request.url.path != "/health":
        key = request.headers.get("X-API-Key", "")
        if key != settings.api_key:
            return JSONResponse(status_code=401, content={"detail": "Invalid or missing API key"})
    return await call_next(request)


# ---------------------------------------------------------------------------
# Error handlers
# ---------------------------------------------------------------------------

@app.exception_handler(ValueError)
async def value_error_handler(request: Request, exc: ValueError) -> JSONResponse:
    return JSONResponse(status_code=400, content={"detail": str(exc)})


@app.exception_handler(Exception)
async def generic_error_handler(request: Request, exc: Exception) -> JSONResponse:
    logger.exception("Unhandled error: %s", exc)
    return JSONResponse(status_code=500, content={"detail": "Internal server error"})


# ---------------------------------------------------------------------------
# Routes
# ---------------------------------------------------------------------------

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
    settings = get_settings()
    logger.info("Starting Chimera AI server on http://%s:%d", settings.host, settings.port)
    uvicorn.run(
        "main:app",
        host=settings.host,
        port=settings.port,
        reload=settings.debug,
    )


if __name__ == "__main__":
    main()
