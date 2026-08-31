from __future__ import annotations

import json
import logging
from pathlib import Path
from typing import Any

import chromadb
from chromadb.config import Settings

logger = logging.getLogger(__name__)

DATA_DIR = Path(__file__).resolve().parent.parent / "data" / "chroma"
RELATIONSHIPS_FILENAME = "relationships.json"


class MemoryStore:
    def __init__(self, persist_dir: Path | None = None) -> None:
        self.persist_dir = persist_dir or DATA_DIR
        self.persist_dir.mkdir(parents=True, exist_ok=True)
        self.client = chromadb.PersistentClient(
            path=str(self.persist_dir),
            settings=Settings(anonymized_telemetry=False),
        )
        self._relationships: dict[tuple[str, str], float] = {}
        self._seed_relationships()
        self._load_relationships()

    def _collection(self, npc_id: str):
        return self.client.get_or_create_collection(
            name=f"npc_{npc_id}",
            metadata={"hnsw:space": "cosine"},
        )

    def _seed_relationships(self) -> None:
        # Directional seeds: (from, to, score)
        pairs = [
            ("alex", "jordan", 0.6),
            ("alex", "sam", 0.3),
            ("jordan", "riley", 0.7),
            ("sam", "morgan", 0.5),
            ("riley", "casey", 0.4),
            ("morgan", "casey", 0.8),
            ("alex", "morgan", -0.2),
            # Reverse directions with independent scores
            ("jordan", "alex", 0.5),
            ("sam", "alex", 0.2),
            ("riley", "jordan", 0.6),
            ("morgan", "sam", 0.4),
            ("casey", "riley", 0.3),
            ("casey", "morgan", 0.7),
            ("morgan", "alex", -0.1),
        ]
        for a, b, score in pairs:
            self._relationships[(a, b)] = score

    def record(self, npc_id: str, text: str, metadata: dict[str, Any] | None = None) -> str:
        collection = self._collection(npc_id)
        doc_id = f"{npc_id}_{collection.count()}"
        meta = metadata or {}
        meta["npc_id"] = npc_id
        collection.add(documents=[text], metadatas=[meta], ids=[doc_id])
        logger.debug("Recorded memory for %s: %s", npc_id, text[:80])
        return doc_id

    def recall(self, npc_id: str, query: str, top_k: int = 5) -> list[str]:
        collection = self._collection(npc_id)
        if collection.count() == 0:
            return []
        results = collection.query(query_texts=[query], n_results=min(top_k, collection.count()))
        docs = results.get("documents", [[]])[0]
        return docs or []

    def update_relationship(self, from_npc: str, to_npc: str, delta: float) -> float:
        key = (from_npc.lower(), to_npc.lower())
        current = self._relationships.get(key, 0.0)
        new_score = max(-1.0, min(1.0, current + delta))
        self._relationships[key] = new_score
        self._save_relationships()
        return new_score

    def get_relationship(self, from_npc: str, to_npc: str) -> float:
        return self._relationships.get((from_npc.lower(), to_npc.lower()), 0.0)

    def _relationships_path(self) -> Path:
        return self.persist_dir / RELATIONSHIPS_FILENAME

    def _load_relationships(self) -> None:
        path = self._relationships_path()
        if not path.exists():
            return
        try:
            entries = json.loads(path.read_text(encoding="utf-8"))
        except (json.JSONDecodeError, OSError):
            logger.warning("Failed to load persisted relationships from %s", path)
            return
        for entry in entries:
            a, b, score = entry["from_npc"], entry["to_npc"], entry["score"]
            self._relationships[(a, b)] = score

    def _save_relationships(self) -> None:
        try:
            self._relationships_path().write_text(
                json.dumps(self.get_relationships()), encoding="utf-8"
            )
        except OSError:
            logger.warning("Failed to persist relationships to %s", self._relationships_path())

    def persist(self) -> None:
        """Explicitly flush ChromaDB and relationships to disk."""
        try:
            self._save_relationships()
            # Force ChromaDB to persist all collections
            for collection in self.client.list_collections():
                collection.modify()
            logger.debug("Memory store persisted to %s", self.persist_dir)
        except Exception as exc:
            logger.warning("Failed to persist memory store: %s", exc)

    def get_relationships(self) -> list[dict[str, Any]]:
        seen: set[tuple[str, str]] = set()
        entries = []
        for (a, b), score in self._relationships.items():
            # Deduplicate: only emit the (a,b) direction where a < b alphabetically
            # OR if it's a truly directional pair (different scores in each direction)
            pair = tuple(sorted([a, b]))
            reverse_key = (b, a)
            reverse_score = self._relationships.get(reverse_key)
            is_asymmetric = reverse_score is not None and abs(score - reverse_score) > 0.01

            if pair in seen and not is_asymmetric:
                continue
            if not is_asymmetric:
                seen.add(pair)

            label = "friend" if score > 0.5 else "rival" if score < -0.1 else "neutral"
            entries.append({"from_npc": a, "to_npc": b, "score": score, "label": label})
        return entries

    def snapshot_path(self) -> str:
        return str(self.persist_dir)
