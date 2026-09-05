#!/usr/bin/env python3
"""Repair truncated tile_map_data in the 5 off-campus location scenes.

Their base64 payloads were written truncated (len % 4 != 0 -> Godot parse error
at load -> LocationManager.travel() to these scenes instantiates null).
Regenerates a complete floor grid for the shared 1120x560-interior template
(floortiles 20px, cells x=4..59, y=4..31 => covers 80..1200 x 80..640).
"""
import base64
import re
import struct
from pathlib import Path

SCENES = Path("C:/Users/aditya/Desktop/project-chimera/godot/scenes/locations")
ROOMS = ["courtyard", "server_room", "library", "hospital", "bar"]


def encode(cells):
    data = struct.pack("<H", 0)
    for x, y, src, ax, ay, alt in cells:
        data += struct.pack("<hhHHHH", x, y, src, ax, ay, alt)
    return base64.b64encode(data).decode("ascii")


cells = [(x, y, 0, 0, 0, 0) for y in range(4, 32) for x in range(4, 60)]
new_line = f'tile_map_data = PackedByteArray("{encode(cells)}")'
print(f"new payload: {len(new_line)} chars")

for name in ROOMS:
    p = SCENES / f"{name}.tscn"
    text = p.read_text(encoding="utf-8")
    text, n = re.subn(
        r'tile_map_data = PackedByteArray\("[^"]*"\)',
        new_line,
        text,
        count=1,
    )
    assert n == 1, name
    p.write_text(text, encoding="utf-8")
    print(f"repaired {name}.tscn")
