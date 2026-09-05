"""Centralized configuration for Chimera AI server."""

from __future__ import annotations

import os
from dataclasses import dataclass, field


@dataclass(frozen=True)
class Settings:
    """Immutable server configuration loaded from environment variables."""

    # Server
    host: str = field(default_factory=lambda: os.environ.get("CHIMERA_HOST", "127.0.0.1"))
    port: int = field(default_factory=lambda: int(os.environ.get("CHIMERA_PORT", "8000")))
    debug: bool = field(default_factory=lambda: os.environ.get("CHIMERA_DEBUG", "false").lower() in ("1", "true"))

    # Auth
    api_key: str = field(default_factory=lambda: os.environ.get("CHIMERA_API_KEY", ""))

    # Ollama
    ollama_url: str = field(default_factory=lambda: os.environ.get("CHIMERA_OLLAMA_URL", "http://localhost:11434"))
    ollama_model: str = field(default_factory=lambda: os.environ.get("CHIMERA_OLLAMA_MODEL", "phi3:mini"))
    ollama_timeout: float = field(default_factory=lambda: float(os.environ.get("CHIMERA_OLLAMA_TIMEOUT", "30.0")))
    ollama_health_timeout: float = field(default_factory=lambda: float(os.environ.get("CHIMERA_OLLAMA_HEALTH_TIMEOUT", "2.0")))

    # CORS
    cors_origins: list[str] = field(default_factory=lambda: _parse_cors_origins())

    @property
    def requires_auth(self) -> bool:
        return bool(self.api_key)


def _parse_cors_origins() -> list[str]:
    raw = os.environ.get("CHIMERA_CORS_ORIGINS", "")
    if raw:
        return [o.strip() for o in raw.split(",") if o.strip()]
    return ["http://localhost:*", "http://127.0.0.1:*"]


_settings: Settings | None = None


def get_settings() -> Settings:
    global _settings
    if _settings is None:
        _settings = Settings()
    return _settings


def reset_settings() -> None:
    """Test helper to reload settings from env."""
    global _settings
    _settings = None
