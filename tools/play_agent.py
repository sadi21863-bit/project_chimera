#!/usr/bin/env python3
"""Autonomous MCP playthrough — an agent that plays Project Chimera by reading
live game state over the bridge and deciding its own next move.

Run with the WINDOWED game open to watch it play:
    uv run python -u tools/play_agent.py
"""

import json
import socket
import sys
import time

sys.stdout.reconfigure(encoding="utf-8", errors="replace")


class Game:
    def __init__(self):
        self.sock = socket.create_connection(("127.0.0.1", 9879), timeout=10)
        self.sock.settimeout(20)

    def cmd(self, command, **args):
        self.sock.sendall((json.dumps({"command": command, "args": args}) + "\n").encode())
        buf = b""
        while not buf.endswith(b"\n"):
            chunk = self.sock.recv(65536)
            if not chunk:
                raise ConnectionError("bridge closed")
            buf += chunk
        return json.loads(buf.decode(errors="replace"))


def say(msg):
    print(msg, flush=True)
    time.sleep(0.4)


def wait_for_investigation(g):
    say("— Title flow: picking 'It was murder' —")
    for _ in range(20):
        r = g.cmd("story_choice", is_murder=True)
        if "error" not in r:
            break
        time.sleep(1.5)  # cinematic still playing; retry until CHOICE is reachable
    st = g.cmd("get_state")
    say(f"  → phase={st['phase']} (INVESTIGATION) | day {st['day']}, {int(st['hour']):02d}:00 @ {st['location']}")


def search_best(g, point_id):
    """Try every action on a search point; keep whatever clues fall out."""
    got = []
    data = g.cmd("get_search_actions", point_id=point_id).get("data", {})
    for a in data.get("actions", []):
        r = g.cmd("search", point_id=point_id, action_id=a["id"])
        found = r.get("clues_found") or []
        got += found
        if found:
            say(f"  🔍 {point_id}/{a['id']} → {', '.join(found)}")
    return got


def main():
    g = Game()
    say("=== AGENT SESSION START ===")
    wait_for_investigation(g)

    say("\n— Sweep the dorm's private rooms —")
    for room, points in {
        "bedroom_1": ["bedroom_1_desk"],          # master key lives here
        "bedroom_2": ["jordan_dresser", "jordan_costume_trunk", "bedroom_2_mirror"],
        "bedroom_3": ["sam_nightstand", "bedroom_3_desk"],
        "common_room": ["common_room_couch"],
        "hallway": ["hall_board", "hallway_vending"],
    }.items():
        g.cmd("travel", destination=room)
        for p in points:
            search_best(g, p)

    say("\n— Hotspot examination (E-interactions) —")
    for clue in ["clue_wiring", "clue_camera"]:
        say(f"  👁 examine → {g.cmd('examine', clue_id=clue)}")

    st = g.cmd("get_state")
    say(f"\n— Evidence so far ({len(st['discovered_clues'])}): {', '.join(sorted(st['discovered_clues']))}")

    say("\n— The locked room: Daniel's —")
    key = "item_master_key" in st["discovered_clues"]
    say(f"  master key {'in pocket ✓' if key else 'MISSING'} — trying the door anyway")
    g.cmd("travel", destination="daniel_room")
    for p in ["daniel_desk", "daniel_ledger", "daniel_nightstand"]:
        search_best(g, p)

    say("\n— Interrogate Sam (styles matter; low trust gets refusals) —")
    g.cmd("travel", destination="dorm")
    for style, name in [(0, "Direct"), (1, "Empathetic"), (2, "Confrontational")]:
        r = g.cmd("interrogate", npc_id="sam", topic_id="that_night", style=style)
        resp = (r.get("response") or "")[:70]
        extra = f" | clue: {r['reveal_clue']}" if r.get("reveal_clue") else ""
        say(f"  🗣 [{name}] \"{resp}...\"{extra}")

    say("\n— Rapport with Riley (witness) before the accusation —")
    g.cmd("rapport", npc_id="riley", approach="listen")

    say("\n— Screenshot the evidence board moment —")
    shot = g.cmd("screenshot", format="png", max_width=960)
    say(f"  📸 {'captured ' + str(shot.get('size_bytes', 0)) + ' bytes' if 'data' in shot else shot.get('error')}")

    say("\n— THE ACCUSATION —")
    res = g.cmd("accuse", suspect_id="sam")
    say(f"  ⚖ {res}")
    final = g.cmd("get_state")
    say(f"\n=== FINALE === phase={final['phase']} ending={res.get('ending_id') or '(rejected)'} "
        f"| day {final['day']}, {int(final['hour']):02d}:00 | clues={len(final['discovered_clues'])}")
    say("=== AGENT SESSION END ===")


if __name__ == "__main__":
    main()
