from __future__ import annotations

from chimera.memory import MemoryStore


def test_record_and_recall(tmp_path):
    store = MemoryStore(persist_dir=tmp_path / "chroma")
    store.record("alex", "Had breakfast with Jordan in the kitchen.")
    results = store.recall("alex", "breakfast kitchen", top_k=3)
    assert results
    assert "breakfast" in results[0].lower()


def test_recall_empty_collection_returns_empty_list(tmp_path):
    store = MemoryStore(persist_dir=tmp_path / "chroma")
    assert store.recall("alex", "anything") == []


def test_get_relationships_labels(tmp_path):
    store = MemoryStore(persist_dir=tmp_path / "chroma")
    entries = {
        (e["from_npc"], e["to_npc"]): e for e in store.get_relationships()
    }
    alex_jordan = entries.get(("alex", "jordan")) or entries.get(("jordan", "alex"))
    assert alex_jordan is not None
    assert alex_jordan["label"] == "friend"  # seeded score 0.6 > 0.5


def test_update_relationship_persists_across_instances(tmp_path):
    persist_dir = tmp_path / "chroma"
    store = MemoryStore(persist_dir=persist_dir)
    new_score = store.update_relationship("alex", "casey", 0.9)
    assert -1.0 <= new_score <= 1.0

    reloaded = MemoryStore(persist_dir=persist_dir)
    entries = {
        (e["from_npc"], e["to_npc"]): e["score"] for e in reloaded.get_relationships()
    }
    score = entries.get(("alex", "casey"))
    if score is None:
        score = entries.get(("casey", "alex"))
    assert score == new_score
