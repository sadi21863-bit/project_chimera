from __future__ import annotations

import httpx
import pytest
import respx

from chimera import llm
from chimera.models import ActionType, NpcContext


def _make_context(**overrides) -> NpcContext:
    defaults = dict(
        npc_id="alex",
        name="Alex",
        personality="Organized RA",
        current_room="bedroom_1",
        schedule_goal="breakfast in kitchen",
        nearby_npcs=[],
        recent_events=[],
        game_hour=8.5,
        game_day=1,
    )
    defaults.update(overrides)
    return NpcContext(**defaults)


async def _async_true() -> bool:
    return True


async def _async_false() -> bool:
    return False


async def _async_fail_if_called() -> bool:
    raise AssertionError("check_ollama_available should not be called while circuit is open")


def test_rule_based_action_moves_toward_schedule_goal():
    action = llm.rule_based_action(_make_context())
    assert action.action == ActionType.MOVE
    assert action.target_room == "kitchen"


def test_rule_based_action_socializes_when_nearby_npc_present():
    ctx = _make_context(
        schedule_goal="free time",
        nearby_npcs=[{"id": "jordan", "name": "Jordan", "room": "common_room"}],
    )
    action = llm.rule_based_action(ctx)
    assert action.action == ActionType.SPEAK
    assert action.target_npc == "jordan"


def test_rule_based_action_idles_with_no_goal_match_or_npcs():
    ctx = _make_context(schedule_goal="free time")
    action = llm.rule_based_action(ctx)
    assert action.action == ActionType.IDLE


def test_extract_json_handles_direct_and_embedded_json():
    assert llm._extract_json('{"a": 1}') == {"a": 1}
    assert llm._extract_json('noise before {"a": 1} noise after') == {"a": 1}
    assert llm._extract_json("not json") is None


@pytest.mark.asyncio
async def test_generate_action_falls_back_when_ollama_down(monkeypatch):
    monkeypatch.setattr(llm, "check_ollama_available", _async_false)
    action, source = await llm.generate_action(_make_context(), [])
    assert source == "rule_based"
    assert action is not None


@pytest.mark.asyncio
async def test_generate_action_uses_ollama_when_available(monkeypatch):
    monkeypatch.setattr(llm, "check_ollama_available", _async_true)
    with respx.mock:
        respx.post(f"{llm.OLLAMA_URL}/api/generate").mock(
            return_value=httpx.Response(
                200, json={"response": '{"action":"idle","reason":"testing"}'}
            )
        )
        action, source = await llm.generate_action(_make_context(), [])
    assert source == "ollama"
    assert action.action == ActionType.IDLE


@pytest.mark.asyncio
async def test_circuit_breaker_opens_after_repeated_failures_and_short_circuits(monkeypatch):
    monkeypatch.setattr(llm, "check_ollama_available", _async_true)
    with respx.mock:
        respx.post(f"{llm.OLLAMA_URL}/api/generate").mock(return_value=httpx.Response(500))
        for _ in range(llm.CIRCUIT_FAILURE_THRESHOLD):
            _, source = await llm.generate_action(_make_context(), [])
            assert source == "rule_based"

    assert llm._circuit_is_open()

    # Once open, the breaker must short-circuit before even checking Ollama health.
    monkeypatch.setattr(llm, "check_ollama_available", _async_fail_if_called)
    _, source = await llm.generate_action(_make_context(), [])
    assert source == "rule_based"
