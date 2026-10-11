"""Regenerates the character SpriteFrames as Archival Cutaway sprites.

The layout is unchanged from the originals: five animations, three 32x32 RGBA8
frames each (idle_down, walk_down, walk_left, walk_right, walk_up). Every
consumer -- npc.gd, detective.gd, the profile factory -- keeps working because
only the pixels change.

Run: python tools/art/generate_archival_characters.py
"""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT_DIR = ROOT / "godot" / "resources" / "sprite_frames"

SIZE = 32

INK = (14, 24, 32)
SKIN = (214, 186, 150)
SKIN_SHADE = (188, 158, 124)
HAIR = (46, 38, 34)
HAIR_GREY = (126, 122, 116)
PAPER = (224, 214, 190)
TROUSERS = (58, 62, 68)

# npc_id -> (coat, coat_shade, hair)
CHARACTERS = {
    "alex": ((86, 132, 128), (58, 96, 94), HAIR),
    "jordan": ((150, 76, 70), (112, 54, 50), (58, 46, 40)),
    "sam": ((82, 108, 146), (56, 76, 108), HAIR),
    "riley": ((104, 84, 128), (74, 58, 94), (36, 30, 34)),
    "morgan": ((88, 118, 84), (60, 86, 60), HAIR_GREY),
    "casey": ((166, 116, 56), (122, 82, 38), (74, 50, 32)),
    "dean": ((84, 96, 108), (58, 68, 80), HAIR_GREY),
    "detective": ((74, 84, 92), (50, 58, 66), (40, 34, 32)),
}

ANIMATIONS = [
    ("idle_down", 5.0),
    ("walk_down", 8.0),
    ("walk_left", 8.0),
    ("walk_right", 8.0),
    ("walk_up", 8.0),
]


class Canvas:
    def __init__(self):
        self.px = [[None] * SIZE for _ in range(SIZE)]

    def put(self, x, y, color):
        if 0 <= x < SIZE and 0 <= y < SIZE and color is not None:
            self.px[y][x] = color

    def rect(self, x0, y0, x1, y1, color):
        for y in range(y0, y1):
            for x in range(x0, x1):
                self.put(x, y, color)

    def shift(self, dy):
        if dy == 0:
            return
        for y in range(SIZE):
            for x in range(SIZE):
                v = self.px[y][x]
                if v is None:
                    continue
                self.px[y][x] = None
                self.put(x, y + dy, v)

    def outline(self):
        filled = [[self.px[y][x] is not None for x in range(SIZE)] for y in range(SIZE)]
        out = [[None] * SIZE for _ in range(SIZE)]
        for y in range(SIZE):
            for x in range(SIZE):
                if not filled[y][x]:
                    continue
                edge = False
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if not (0 <= nx < SIZE and 0 <= ny < SIZE) or not filled[ny][nx]:
                        edge = True
                        break
                out[y][x] = INK if edge else self.px[y][x]
        self.px = out

    def to_rgba_bytes(self):
        data = bytearray()
        for y in range(SIZE):
            for x in range(SIZE):
                c = self.px[y][x]
                if c is None:
                    data += bytes((0, 0, 0, 0))
                else:
                    data += bytes((c[0], c[1], c[2], 255))
        return bytes(data)


def draw_character(coat, coat_shade, hair, facing, bob, leg_phase, arm_phase):
    c = Canvas()

    # legs
    leg_y = 25 + bob
    if leg_phase == 0:
        c.rect(12, leg_y, 15, 31, TROUSERS)
        c.rect(17, leg_y, 20, 31, TROUSERS)
        c.rect(11, 30, 15, 32, INK)
        c.rect(17, 30, 21, 32, INK)
    elif leg_phase == 1:
        c.rect(13, leg_y, 16, 31, TROUSERS)
        c.rect(16, leg_y, 19, 30, TROUSERS)
        c.rect(12, 30, 16, 32, INK)
        c.rect(16, 29, 20, 31, INK)
    else:
        c.rect(13, leg_y, 16, 30, TROUSERS)
        c.rect(16, leg_y, 19, 31, TROUSERS)
        c.rect(12, 29, 16, 31, INK)
        c.rect(16, 30, 20, 32, INK)

    # torso / coat
    c.rect(10, 17 + bob, 22, 25 + bob, coat)
    c.rect(19, 17 + bob, 22, 25 + bob, coat_shade)
    c.rect(10, 24 + bob, 22, 25 + bob, coat_shade)
    c.put(16, 18 + bob, coat_shade)
    c.put(16, 20 + bob, coat_shade)
    c.put(16, 22 + bob, coat_shade)
    c.put(15, 24 + bob, coat_shade)
    c.put(17, 24 + bob, coat_shade)

    # arms
    arm_y = 18 + bob
    c.rect(8 + arm_phase, arm_y, 10 + arm_phase, 24 + bob, coat)
    c.rect(22 - arm_phase, arm_y, 24 - arm_phase, 24 + bob, coat)
    c.rect(8 + arm_phase, 24 + bob, 10 + arm_phase, 25 + bob, SKIN)
    c.rect(22 - arm_phase, 24 + bob, 24 - arm_phase, 25 + bob, SKIN)

    # neck + head
    c.rect(14, 15 + bob, 18, 17 + bob, SKIN_SHADE)
    c.rect(11, 6 + bob, 21, 16 + bob, SKIN)
    c.rect(19, 8 + bob, 21, 14 + bob, SKIN_SHADE)

    if facing == "up":
        c.rect(11, 5 + bob, 21, 11 + bob, hair)
    else:
        c.rect(11, 5 + bob, 21, 9 + bob, hair)
        c.rect(11, 5 + bob, 13, 12 + bob, hair)
        if facing == "down":
            c.put(14, 11 + bob, INK)
            c.put(18, 11 + bob, INK)
            c.rect(15, 14 + bob, 17, 14 + bob, SKIN_SHADE)
        else:
            c.put(13 if facing == "left" else 19, 11 + bob, INK)

    c.outline()
    return c


def frames_for(anim, coat, coat_shade, hair):
    if anim == "idle_down":
        return [
            draw_character(coat, coat_shade, hair, "down", 0, 0, 0),
            draw_character(coat, coat_shade, hair, "down", -1, 0, 0),
            draw_character(coat, coat_shade, hair, "down", 0, 0, 0),
        ]
    if anim == "walk_down":
        return [
            draw_character(coat, coat_shade, hair, "down", 0, 0, 0),
            draw_character(coat, coat_shade, hair, "down", -1, 1, -1),
            draw_character(coat, coat_shade, hair, "down", 0, 2, 1),
        ]
    if anim == "walk_up":
        return [
            draw_character(coat, coat_shade, hair, "up", 0, 0, 0),
            draw_character(coat, coat_shade, hair, "up", -1, 1, -1),
            draw_character(coat, coat_shade, hair, "up", 0, 2, 1),
        ]
    facing = "left" if anim == "walk_left" else "right"
    return [
        draw_character(coat, coat_shade, hair, facing, 0, 0, 0),
        draw_character(coat, coat_shade, hair, facing, -1, 1, -1),
        draw_character(coat, coat_shade, hair, facing, 0, 2, 1),
    ]


def fmt_packed(raw):
    return ", ".join(str(b) for b in raw)


def build_tres(npc_id):
    coat, coat_shade, hair = CHARACTERS[npc_id]
    parts = ['[gd_resource type="SpriteFrames" format=3]\n']
    anim_blocks = []

    for anim_index, (anim, speed) in enumerate(ANIMATIONS):
        frame_refs = []
        for frame_index, canvas in enumerate(frames_for(anim, coat, coat_shade, hair)):
            image_id = "Image_%s_%d_%d" % (npc_id, anim_index, frame_index)
            tex_id = "ImageTexture_%s_%d_%d" % (npc_id, anim_index, frame_index)
            parts.append('[sub_resource type="Image" id="%s"]' % image_id)
            parts.append("data = {")
            parts.append('"data": PackedByteArray(%s),' % fmt_packed(canvas.to_rgba_bytes()))
            parts.append('"format": "RGBA8",')
            parts.append('"height": %d,' % SIZE)
            parts.append('"mipmaps": false,')
            parts.append('"width": %d' % SIZE)
            parts.append("}")
            parts.append("")
            parts.append('[sub_resource type="ImageTexture" id="%s"]' % tex_id)
            parts.append('image = SubResource("%s")' % image_id)
            parts.append("")
            frame_refs.append(tex_id)

        frames = []
        for tex_id in frame_refs:
            frames.append('{\n"duration": 1.0,\n"texture": SubResource("%s")\n}' % tex_id)
        anim_blocks.append(
            '"frames": [%s],\n"loop": 1,\n"name": &"%s",\n"speed": %s'
            % (", ".join(frames), anim, speed)
        )

    parts.append("[resource]")
    parts.append("animations = [%s]\n" % ", ".join(
        "{\n%s\n}" % block for block in anim_blocks
    ))
    return "\n".join(parts)


def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for npc_id in CHARACTERS:
        target = OUT_DIR / ("%s.tres" % npc_id)
        target.write_text(build_tres(npc_id), encoding="utf-8")
        print("wrote", target)


if __name__ == "__main__":
    main()