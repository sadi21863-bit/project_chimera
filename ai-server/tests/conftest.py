from __future__ import annotations

import pytest

from chimera import llm


@pytest.fixture(autouse=True)
def _reset_circuit_breaker():
    llm.reset_circuit_breaker()
    yield
    llm.reset_circuit_breaker()
