"""Verify Chimera AI server starts and responds."""

import asyncio
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))


async def main() -> None:
    from httpx import ASGITransport, AsyncClient

    from main import app

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        health = await client.get("/health")
        assert health.status_code == 200, health.text
        print("GET /health:", health.json())

        decide = await client.post("/npc/decide", json={
            "context": {
                "npc_id": "alex",
                "name": "Alex",
                "personality": "Organized RA",
                "current_room": "bedroom_1",
                "schedule_goal": "breakfast in kitchen",
                "nearby_npcs": [],
                "recent_events": [],
                "game_hour": 8.5,
                "game_day": 1,
            }
        })
        assert decide.status_code == 200, decide.text
        print("POST /npc/decide:", decide.json())

        record = await client.post("/memory/record", json={
            "npc_id": "alex",
            "text": "Test memory entry",
            "event_type": "test",
        })
        assert record.status_code == 200, record.text
        print("POST /memory/record:", record.json())

        recall = await client.post("/memory/recall", json={
            "npc_id": "alex",
            "query": "test",
            "top_k": 3,
        })
        assert recall.status_code == 200, recall.text
        print("POST /memory/recall:", recall.json())

        inject = await client.post("/events/inject", json={
            "text": "Fire drill in hallway",
            "severity": "urgent",
            "target_room": "hallway",
        })
        assert inject.status_code == 200, inject.text
        print("POST /events/inject:", inject.json())

        rels = await client.get("/relationships")
        assert rels.status_code == 200, rels.text
        print("GET /relationships:", rels.json())

    print("\nAll endpoint checks passed.")


if __name__ == "__main__":
    asyncio.run(main())
