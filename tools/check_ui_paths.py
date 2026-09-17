import re
import pathlib

BASE = pathlib.Path("C:/Users/aditya/Desktop/project-chimera/godot")
pairs = [
    ("scripts/ui/accusation_reveal.gd", "scenes/ui/accusation_reveal.tscn"),
    ("scripts/ui/investigation_hud.gd", "scenes/ui/investigation_hud.tscn"),
    ("scenes/ui/dialogue_panel.gd", "scenes/ui/dialogue_panel.tscn"),
]
NODE_RE = re.compile(r'\[node name="([^"]+)"(?: type="[^"]+")? parent="([^"]+)"\]')
PATH_RE = re.compile(r'\$([A-Za-z0-9_/]+)')
for gd, tscn in pairs:
    nodes = set()
    for m in NODE_RE.finditer((BASE / tscn).read_text(encoding="utf-8")):
        name, parent = m.groups()
        nodes.add(parent + "/" + name if parent != "." else name)
    print("==", gd)
    for p in sorted(set(PATH_RE.findall((BASE / gd).read_text(encoding="utf-8")))):
        print(("OK   " if p in nodes else "MISS ") + p)
