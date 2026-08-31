from __future__ import annotations

import json
import logging
import re
import time
from pathlib import Path
from typing import Any

import httpx

from chimera.config import get_settings
from chimera.models import ActionType, NpcAction, NpcContext

logger = logging.getLogger(__name__)

# Circuit breaker: after enough consecutive failures, skip the health check
# and go straight to the rule-based fallback for a cooldown window instead of
# paying the timeout cost on every decision tick.
CIRCUIT_FAILURE_THRESHOLD = 3
CIRCUIT_RESET_SECONDS = 30.0

_consecutive_failures = 0
_circuit_open_until = 0.0

PROMPTS_DIR = Path(__file__).resolve().parent / "prompts"

# Shared HTTP client — created lazily, reused across all requests
_http_client: httpx.AsyncClient | None = None


def _load_prompt(name: str) -> str:
    return (PROMPTS_DIR / name).read_text(encoding="utf-8").strip()


SYSTEM_PROMPT = _load_prompt("system.txt")
PERSONA_TEMPLATE = _load_prompt("npc_persona.txt")


def reset_circuit_breaker() -> None:
    """Test helper to clear circuit-breaker state between runs."""
    global _consecutive_failures, _circuit_open_until
    _consecutive_failures = 0
    _circuit_open_until = 0.0


def _circuit_is_open() -> bool:
    return time.monotonic() < _circuit_open_until


def _record_success() -> None:
    global _consecutive_failures
    _consecutive_failures = 0


def _record_failure() -> None:
    global _consecutive_failures, _circuit_open_until
    _consecutive_failures += 1
    if _consecutive_failures >= CIRCUIT_FAILURE_THRESHOLD:
        _circuit_open_until = time.monotonic() + CIRCUIT_RESET_SECONDS
        logger.warning(
            "Ollama circuit breaker open for %.0fs after %d consecutive failures",
            CIRCUIT_RESET_SECONDS,
            _consecutive_failures,
        )


async def get_http_client() -> httpx.AsyncClient:
    """Get or create the shared async HTTP client."""
    global _http_client
    if _http_client is None or _http_client.is_closed:
        settings = get_settings()
        _http_client = httpx.AsyncClient(
            timeout=httpx.Timeout(settings.ollama_timeout, connect=5.0),
            limits=httpx.Limits(
                max_connections=10,
                max_keepalive_connections=5,
                keepalive_expiry=120,
            ),
        )
    return _http_client


async def close_http_client() -> None:
    """Shut down the shared HTTP client."""
    global _http_client
    if _http_client is not None and not _http_client.is_closed:
        await _http_client.aclose()
        _http_client = None


async def check_ollama_available() -> bool:
    settings = get_settings()
    try:
        client = await get_http_client()
        response = await client.get(
            f"{settings.ollama_url}/api/tags",
            timeout=httpx.Timeout(settings.ollama_health_timeout),
        )
        return response.status_code == 200
    except Exception:
        return False


def _extract_json(text: str) -> dict[str, Any] | None:
    text = text.strip()
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        pass
    match = re.search(r"\{.*\}", text, re.DOTALL)
    if match:
        try:
            return json.loads(match.group(0))
        except json.JSONDecodeError:
            return None
    return None


def _safe_room_from_npc_id(npc_id: str) -> str:
    """Extract bedroom number from NPC ID, fallback to bedroom_1."""
    # Try numeric suffix first (alex -> 1, jordan -> 2, etc.)
    suffix = npc_id[-1] if npc_id else ""
    if suffix.isdigit():
        return f"bedroom_{suffix}"
    # Try known mappings
    npc_room_map = {
        "alex": "bedroom_1",
        "jordan": "bedroom_2",
        "sam": "bedroom_3",
        "riley": "bedroom_4",
        "morgan": "bedroom_5",
        "casey": "bedroom_6",
    }
    return npc_room_map.get(npc_id.lower(), "bedroom_1")


def _time_based_goal(game_hour: float) -> str:
    """Infer a reasonable goal from time of day."""
    if game_hour < 7.0:
        return "sleeping in bedroom"
    elif game_hour < 9.0:
        return "breakfast in kitchen"
    elif game_hour < 12.0:
        return "morning activities"
    elif game_hour < 14.0:
        return "lunch in kitchen"
    elif game_hour < 17.0:
        return "afternoon activities"
    elif game_hour < 19.0:
        return "dinner in kitchen"
    elif game_hour < 22.0:
        return "evening in common_room"
    else:
        return "sleeping in bedroom"


def rule_based_action(context: NpcContext) -> NpcAction:
    """Fallback when Ollama unavailable."""
    goal = context.schedule_goal.lower()

    # Time-based inference if no explicit goal
    if not goal or goal in ("free time", "idle", ""):
        goal = _time_based_goal(context.game_hour).lower()

    room_map = {
        "kitchen": "kitchen",
        "common": "common_room",
        "bedroom": _safe_room_from_npc_id(context.npc_id),
        "bathroom": "bathroom",
        "hallway": "hallway",
        "dorm": "common_room",
        "study": "common_room",
        "library": "common_room",
    }

    for keyword, room in room_map.items():
        if keyword in goal and room != context.current_room:
            return NpcAction(action=ActionType.MOVE, target_room=room, reason="schedule fallback")

    # Night hours: go to bedroom
    if context.game_hour >= 22.0 or context.game_hour < 6.0:
        bedroom = _safe_room_from_npc_id(context.npc_id)
        if context.current_room != bedroom:
            return NpcAction(action=ActionType.MOVE, target_room=bedroom, reason="nighttime rest")

    if context.nearby_npcs:
        other = context.nearby_npcs[0]
        return NpcAction(
            action=ActionType.SPEAK,
            target_npc=other.id,
            text=f"Hey {other.name}, good to see you.",
            reason="social fallback",
        )
    return NpcAction(action=ActionType.IDLE, reason="schedule fallback")


def _build_prompt(context: NpcContext, memories: list[str]) -> str:
    memory_block = "\n".join(f"- {m}" for m in memories[:5]) or "- No relevant memories."
    persona = PERSONA_TEMPLATE.format(
        name=context.name,
        personality=context.personality,
        current_room=context.current_room,
        schedule_goal=context.schedule_goal,
        secrets=", ".join(context.secrets) or "none",
    )
    return f"""{SYSTEM_PROMPT}

{persona}

Game time: Day {context.game_day}, hour {context.game_hour:.1f}
Nearby NPCs: {", ".join(n.name for n in context.nearby_npcs) or "none"}
Recent events:
{chr(10).join(context.recent_events[-5:]) or "- none"}

Memories:
{memory_block}

Respond with ONLY valid JSON matching this schema:
{{"action":"move|speak|idle|interact","target_room":"room_id or null","target_npc":"npc_id or null","text":"dialogue or null","interact_object":"object or null","reason":"brief reason"}}

Valid rooms: bedroom_1, bedroom_2, bedroom_3, bedroom_4, bedroom_5, bedroom_6, common_room, kitchen, bathroom, hallway
Valid NPCs: alex, jordan, sam, riley, morgan, casey
"""


async def generate_action(context: NpcContext, memories: list[str]) -> tuple[NpcAction, str]:
    if _circuit_is_open():
        logger.info("Ollama circuit open — using rule-based fallback")
        return rule_based_action(context), "rule_based"

    ollama_up = await check_ollama_available()
    if not ollama_up:
        logger.info("Ollama unavailable — using rule-based fallback")
        return rule_based_action(context), "rule_based"

    settings = get_settings()
    prompt = _build_prompt(context, memories)

    payload = {
        "model": settings.ollama_model,
        "prompt": prompt,
        "stream": False,
        "format": "json",
    }

    try:
        client = await get_http_client()
        response = await client.post(f"{settings.ollama_url}/api/generate", json=payload)
        response.raise_for_status()
        body = response.json()
        raw = body.get("response", "")
        parsed = _extract_json(raw)
        if parsed:
            action = NpcAction.model_validate(parsed)
            _record_success()
            return action, "ollama"
    except Exception as exc:
        logger.warning("Ollama generation failed: %s", exc)

    _record_failure()
    return rule_based_action(context), "rule_based"
