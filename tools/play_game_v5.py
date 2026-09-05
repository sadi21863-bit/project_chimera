"""
Play Game v5 — Full playthrough via MCP server.

This script goes through the MCP tool layer instead of raw TCP,
validating the complete MCP stack: formatting, error handling, annotations.
"""

import sys
import os
import json
import time
import base64

# Redirected stdout/stderr default to locale encoding (cp1252 on Windows) and
# crash on emoji in tool output; force UTF-8 with replacement.
for _stream in (sys.stdout, sys.stderr):
    if hasattr(_stream, "reconfigure"):
        _stream.reconfigure(encoding="utf-8", errors="replace")

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "mcp"))
from mcp_client import MCPClient, get_tool_text, get_tool_images, is_tool_error


class MCPGamePlayer:
    def __init__(self):
        self.client = MCPClient()
        self.log = []
        self.clues_found = []
        self.screenshot_count = 0

    def call(self, tool_name: str, args: dict = None) -> dict:
        """Call an MCP tool and log the result."""
        _t0 = time.time()
        result = self.client.call_tool(tool_name, args or {})
        print(f"    [{tool_name} took {time.time()-_t0:.2f}s]", flush=True)
        error = is_tool_error(result)
        text = get_tool_text(result)
        images = get_tool_images(result)

        entry = {
            "tool": tool_name,
            "args": args or {},
            "error": error,
            "text": text,
            "has_image": len(images) > 0,
        }
        self.log.append(entry)

        status = "ERROR" if error else "OK"
        print(f"\n{'='*60}")
        print(f"[{status}] {tool_name}")
        if args:
            print(f"  Args: {json.dumps(args)}")
        # Truncate long text
        display_text = text[:500] + "..." if len(text) > 500 else text
        print(f"  Result:\n{display_text}")
        if images:
            print(f"  [image: {images[0].get('mimeType', 'unknown')}]")
        print(f"{'='*60}")

        return result

    def save_screenshots(self, result: dict, label: str):
        """Save any images from tool result."""
        images = get_tool_images(result)
        for img in images:
            if img.get("data"):
                self.screenshot_count += 1
                img_dir = os.path.join(os.path.dirname(__file__), "screenshots")
                os.makedirs(img_dir, exist_ok=True)
                mime = img.get("mimeType", "image/png")
                ext = "jpg" if "jpeg" in mime or "jpg" in mime else "png"
                path = os.path.join(img_dir, f"mcp_play_{self.screenshot_count:02d}_{label}.{ext}")
                with open(path, "wb") as f:
                    f.write(base64.b64decode(img["data"]))
                print(f"  Screenshot saved: {path}")

    def play(self):
        print("="*60)
        print("PROJECT CHIMERA — MCP PLAYTHROUGH v5")
        print("="*60)

        # Connect to MCP server
        print("\nConnecting to MCP server...")
        if not self.client.connect():
            print("FATAL: Could not connect to MCP server")
            return

        tools = self.client.get_tools()
        print(f"Connected! {len(tools)} MCP tools available:")
        for t in tools:
            print(f"  {t['name']}")

        # ---- STATIC TOOLS (chimera.js) ----
        print("\n" + "#"*60)
        print("# PHASE 1: STATIC DATA TOOLS (chimera.js)")
        print("#"*60)

        self.call("chimera_project_info")
        self.call("chimera_get_locations")
        self.call("chimera_get_npcs")
        self.call("chimera_get_clues")
        self.call("chimera_get_endings")
        self.call("chimera_get_gossip")
        self.call("chimera_get_suspicion_moments")
        self.call("chimera_get_sfx_data")
        self.call("chimera_get_search_points")
        self.call("chimera_list_files", {"directory": "tests"})
        self.call("chimera_read_file", {"path": "project.godot"})

        # ---- RUNTIME TOOLS (runtime.js) ----
        print("\n" + "#"*60)
        print("# PHASE 2: GAME STATE & EXPLORATION")
        print("#"*60)

        # Initial state
        result = self.call("chimera_runtime_state")
        self.save_screenshots(result, "initial_state")

        # Scheduled events
        self.call("chimera_runtime_scheduled_events", {
            "day": 1, "hour": 7, "lookahead_hours": 168
        })

        # Search actions
        self.call("chimera_runtime_search_actions", {})

        # Evidence quality
        self.call("chimera_runtime_evidence_quality")

        # Time
        self.call("chimera_runtime_time")

        # NPCs
        self.call("chimera_runtime_npcs")

        # Clues
        self.call("chimera_runtime_clues")

        # Endings
        self.call("chimera_runtime_endings")

        # Relationships
        self.call("chimera_runtime_relationships")

        # ---- SEARCH DORM ----
        print("\n" + "#"*60)
        print("# PHASE 3: SEARCH DORM")
        print("#"*60)

        for point in ["desk_case_notes", "common_room_couch", "hall_board"]:
            result = self.call("chimera_runtime_search", {"point_id": point})
            if "clues_found" in get_tool_text(result):
                # Parse clues from text
                text = get_tool_text(result)
                if "clue_" in text:
                    import re
                    clues = re.findall(r"clue_\w+", text)
                    self.clues_found.extend(clues)

        # ---- RILEY ----
        print("\n" + "#"*60)
        print("# PHASE 4: RILEY INTERROGATION")
        print("#"*60)

        self.call("chimera_runtime_rapport", {"npc_id": "riley", "approach": "listen"})

        result = self.call("chimera_runtime_interrogate", {
            "npc_id": "riley", "topic_id": "that_night", "style": 1
        })
        result = self.call("chimera_runtime_interrogate", {
            "npc_id": "riley", "topic_id": "the_pills", "style": 1
        })

        # ---- JORDAN ----
        print("\n" + "#"*60)
        print("# PHASE 5: JORDAN INTERROGATION")
        print("#"*60)

        self.call("chimera_runtime_rapport", {"npc_id": "jordan", "approach": "listen"})

        result = self.call("chimera_runtime_interrogate", {
            "npc_id": "jordan", "topic_id": "that_night", "style": 1
        })
        result = self.call("chimera_runtime_interrogate", {
            "npc_id": "jordan", "topic_id": "the_lie", "style": 1
        })
        self.save_screenshots(result, "after_jordan")

        # ---- SAM ----
        print("\n" + "#"*60)
        print("# PHASE 6: SAM INTERROGATION")
        print("#"*60)

        self.call("chimera_runtime_rapport", {"npc_id": "sam", "approach": "compliment"})
        self.call("chimera_runtime_rapport", {"npc_id": "sam", "approach": "small_talk"})

        result = self.call("chimera_runtime_interrogate", {
            "npc_id": "sam", "topic_id": "that_night", "style": 1
        })
        result = self.call("chimera_runtime_interrogate", {
            "npc_id": "sam", "topic_id": "the_camera", "style": 1
        })
        result = self.call("chimera_runtime_interrogate", {
            "npc_id": "sam", "topic_id": "the_favor", "style": 1
        })
        self.save_screenshots(result, "after_sam")

        # ---- LIBRARY ----
        print("\n" + "#"*60)
        print("# PHASE 7: LIBRARY")
        print("#"*60)

        self.call("chimera_runtime_travel", {"destination": "library"})
        result = self.call("chimera_runtime_search", {"point_id": "library_research"})
        self.save_screenshots(result, "library")

        # ---- DEAN ----
        print("\n" + "#"*60)
        print("# PHASE 8: DEAN INTERROGATION")
        print("#"*60)

        self.call("chimera_runtime_travel", {"destination": "police_station"})
        self.call("chimera_runtime_rapport", {"npc_id": "dean", "approach": "listen"})
        self.call("chimera_runtime_rapport", {"npc_id": "dean", "approach": "share"})

        result = self.call("chimera_runtime_interrogate", {
            "npc_id": "dean", "topic_id": "that_night", "style": 1
        })
        result = self.call("chimera_runtime_interrogate", {
            "npc_id": "dean", "topic_id": "the_double_life", "style": 1
        })
        result = self.call("chimera_runtime_interrogate", {
            "npc_id": "dean", "topic_id": "the_family", "style": 1
        })
        self.save_screenshots(result, "after_dean")

        # ---- STANDING ADJUSTMENT ----
        print("\n" + "#"*60)
        print("# PHASE 9: STANDING ADJUSTMENT")
        print("#"*60)

        self.call("chimera_runtime_adjust_standing", {
            "npc_id": "riley", "delta": 0.2
        })

        # ---- ACCUSATION ----
        print("\n" + "#"*60)
        print("# PHASE 10: ACCUSATION")
        print("#"*60)

        result = self.call("chimera_runtime_accuse", {"suspect_id": "jordan"})
        self.save_screenshots(result, "accusation")

        # ---- SCREENSHOT ----
        print("\n" + "#"*60)
        print("# PHASE 11: SCREENSHOT TEST")
        print("#"*60)

        result = self.call("chimera_runtime_screenshot", {
            "format": "jpg", "max_width": 640
        })
        self.save_screenshots(result, "final_screenshot")

        # ---- FINAL STATE ----
        self.call("chimera_runtime_state")

        # ---- SUMMARY ----
        print("\n" + "="*60)
        print("MCP PLAYTHROUGH SUMMARY")
        print("="*60)

        errors = [l for l in self.log if l["error"]]
        static_calls = [l for l in self.log if l["tool"].startswith("chimera_") and "runtime" not in l["tool"]]
        runtime_calls = [l for l in self.log if "runtime" in l["tool"]]
        screenshots = [l for l in self.log if l["has_image"]]

        print(f"Total MCP tool calls: {len(self.log)}")
        print(f"  Static tools (chimera.js): {len(static_calls)}")
        print(f"  Runtime tools (runtime.js): {len(runtime_calls)}")
        print(f"  Errors: {len(errors)}")
        print(f"  Screenshots captured: {len(screenshots)}")
        print(f"  Clues found: {self.clues_found}")

        if errors:
            print("\nErrors encountered:")
            for e in errors:
                print(f"  [{e['tool']}] {e['text'][:100]}")

        # Tool coverage
        print(f"\nTool coverage:")
        all_tool_names = [t["name"] for t in tools]
        used_tool_names = set(l["tool"] for l in self.log)
        unused = set(all_tool_names) - used_tool_names
        if unused:
            print(f"  Unused tools: {unused}")
        else:
            print(f"  All {len(all_tool_names)} tools exercised!")

        self.client.disconnect()


if __name__ == "__main__":
    player = MCPGamePlayer()
    player.play()
