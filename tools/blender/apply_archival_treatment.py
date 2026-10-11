from pathlib import Path
from PIL import Image, ImageChops, ImageDraw, ImageEnhance, ImageFilter
import random

ROOT = Path(__file__).resolve().parents[2]
ASSET_DIR = ROOT / "godot" / "assets" / "prototypes"


def add_grain(image, seed, strength):
    random.seed(seed)
    width, height = image.size
    noise = Image.new("L", (width, height))
    pixels = noise.load()
    for y in range(height):
        for x in range(width):
            pixels[x, y] = random.randint(0, strength)
    layer = Image.merge("RGBA", (noise, noise, noise, noise.point(lambda p: int(p * 0.42))))
    return Image.alpha_composite(image.convert("RGBA"), layer)


def add_vignette(image, strength):
    width, height = image.size
    mask = Image.new("L", (width, height), 0)
    draw = ImageDraw.Draw(mask)
    steps = 26
    for i in range(steps):
        inset = int(min(width, height) * 0.02 * i)
        alpha = int(strength * (1.0 - i / steps))
        draw.ellipse((inset, inset, width - inset, height - inset), outline=alpha, width=8)
    mask = mask.filter(ImageFilter.GaussianBlur(18))
    dark = Image.new("RGBA", image.size, (5, 10, 14, 255))
    dark.putalpha(mask)
    return Image.alpha_composite(image.convert("RGBA"), dark)


def add_halftone(image, night=False):
    width, height = image.size
    overlay = Image.new("RGBA", image.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    color = (18, 30, 38, 20 if not night else 12)
    spacing = 8
    radius = 1
    for y in range(4, height, spacing):
        for x in range(4, width, spacing):
            if (x * 7 + y * 11) % 5 == 0:
                draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=color)
    return Image.alpha_composite(image.convert("RGBA"), overlay)


def treat(source, target, night=False):
    image = Image.open(source).convert("RGBA")
    image = ImageEnhance.Color(image).enhance(0.78 if not night else 0.68)
    image = ImageEnhance.Contrast(image).enhance(1.16 if not night else 1.24)
    image = ImageEnhance.Brightness(image).enhance(0.98 if not night else 0.92)
    gray = image.convert("L")
    edges = gray.filter(ImageFilter.FIND_EDGES).convert("L")
    edges = edges.point(lambda p: 0 if p < 16 else min(190, int((p - 16) * 2.4)))
    ink = Image.new("RGBA", image.size, (14, 24, 32, 255))
    ink.putalpha(edges)
    image = Image.alpha_composite(image, ink)
    image = add_halftone(image, night)
    image = add_grain(image, 1337 if not night else 7331, 20 if not night else 14)
    image = add_vignette(image, 80 if not night else 110)
    image.convert("RGB").save(target, optimize=True)


def ImageOps_grayscale(image):
    return image.convert("L").convert("RGBA")


for name, is_night in (
    ("archival_cutaway_room_day.png", False),
    ("archival_cutaway_room_night.png", True),
    ("archival_dorm_backdrop_day.png", False),
    ("archival_dorm_backdrop_night.png", True),
):
    source = ASSET_DIR / name
    target = ASSET_DIR / name.replace(".png", "_inked.png")
    treat(source, target, is_night)
    print(target)
