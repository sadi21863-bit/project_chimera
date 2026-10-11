import bpy
import os
import math
from mathutils import Vector

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "godot", "assets", "prototypes")
os.makedirs(OUT, exist_ok=True)

COLORS = {
    "carbon": (0.035, 0.055, 0.075, 1.0),
    "slate": (0.12, 0.19, 0.23, 1.0),
    "slate_light": (0.24, 0.33, 0.36, 1.0),
    "floor": (0.31, 0.40, 0.36, 1.0),
    "floor_alt": (0.38, 0.42, 0.40, 1.0),
    "linoleum": (0.55, 0.53, 0.45, 1.0),
    "paper": (0.72, 0.68, 0.58, 1.0),
    "paper_light": (0.86, 0.82, 0.70, 1.0),
    "green": (0.19, 0.32, 0.27, 1.0),
    "green_light": (0.31, 0.46, 0.37, 1.0),
    "teal": (0.12, 0.30, 0.32, 1.0),
    "teal_light": (0.30, 0.47, 0.47, 1.0),
    "amber": (0.78, 0.36, 0.08, 1.0),
    "amber_light": (1.0, 0.55, 0.16, 1.0),
    "red": (0.48, 0.10, 0.09, 1.0),
    "wood": (0.30, 0.18, 0.10, 1.0),
    "wood_light": (0.48, 0.31, 0.18, 1.0),
    "metal": (0.32, 0.37, 0.38, 1.0),
    "black": (0.008, 0.012, 0.016, 1.0),
}


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)


def material(name, emission=0.0):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    color = COLORS[name]
    mat.diffuse_color = color
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = color
    bsdf.inputs["Roughness"].default_value = 0.82
    if emission > 0.0:
        if "Emission Color" in bsdf.inputs:
            bsdf.inputs["Emission Color"].default_value = color
        if "Emission Strength" in bsdf.inputs:
            bsdf.inputs["Emission Strength"].default_value = emission
    return mat


def box(name, x, y, sx, sy, height, mat, z=0.0, bevel=0.0):
    bpy.ops.mesh.primitive_cube_add(location=(x, y, z + height * 0.5))
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = (sx, sy, height)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(material(mat))
    if bevel > 0.0:
        mod = obj.modifiers.new("SoftEdge", "BEVEL")
        mod.width = bevel
        mod.segments = 2
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.modifier_apply(modifier=mod.name)
    return obj


def cylinder(name, x, y, radius, depth, mat, z=0.0, vertices=16):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=(x, y, z + depth * 0.5))
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(material(mat))
    return obj


def rug(name, x, y, sx, sy, mat):
    return box(name, x, y, sx, sy, 1.0, mat, z=1.0, bevel=4.0)


def wall_h(x0, x1, y, thickness=14.0, height=42.0, mat="carbon"):
    return box("WallH", (x0 + x1) * 0.5, y, x1 - x0, thickness, height, mat, z=0.0)


def wall_v(y0, y1, x, thickness=14.0, height=42.0, mat="carbon"):
    return box("WallV", x, (y0 + y1) * 0.5, thickness, y1 - y0, height, mat, z=0.0)


def build_shell():
    box("Foundation", 640, 360, 1280, 720, 26, "slate", z=-26.0)
    box("KitchenFloor", 245, 143, 410, 205, 4, "floor")
    box("HallFloor", 550, 143, 200, 205, 4, "linoleum")
    box("BathroomFloor", 945, 143, 590, 205, 4, "floor_alt")
    box("CommonFloor", 350, 373, 620, 235, 4, "floor")
    box("EastLoungeFloor", 950, 373, 580, 235, 4, "floor_alt")
    box("HallNorth", 640, 250, 1200, 12, 4, "linoleum")
    box("HallSouth", 640, 495, 1200, 12, 4, "linoleum")
    for i in range(6):
        x = 140 + i * 200
        mat = "floor" if i % 2 == 0 else "floor_alt"
        box("BedroomFloor%d" % i, x, 590, 198, 178, 4, mat)
    wall_h(0, 1280, 20)
    wall_h(0, 1280, 700)
    wall_v(0, 720, 20)
    wall_v(0, 720, 1260)
    wall_v(40, 245, 450)
    wall_v(40, 245, 650)
    wall_h(40, 440, 245)
    wall_h(580, 1240, 245)
    wall_h(40, 1240, 495)
    wall_v(255, 495, 660)
    wall_v(500, 680, 240)
    wall_v(500, 680, 440)
    wall_v(500, 680, 640)
    wall_v(500, 680, 840)
    wall_v(500, 680, 1040)
    for x in (120, 280, 440, 600, 760, 920, 1080):
        box("Threshold", x, 496, 44, 18, 3, "amber", z=5.0)
    for x in (120, 320, 520, 720, 920, 1120):
        box("BedroomEntry", x, 502, 40, 10, 2, "paper_light", z=6.0)


def build_kitchen():
    box("KitchenCounterA", 150, 85, 220, 52, 34, "teal", z=4.0, bevel=5.0)
    box("KitchenTopA", 150, 85, 232, 60, 5, "metal", z=38.0)
    box("KitchenCounterB", 350, 150, 60, 150, 34, "teal", z=4.0, bevel=5.0)
    box("KitchenTopB", 350, 150, 68, 162, 5, "metal", z=38.0)
    box("Stove", 150, 85, 78, 44, 6, "black", z=43.0)
    for dx in (-20, 0, 20):
        cylinder("Burner", 150 + dx, 85, 7, 2, "metal", z=49.0, vertices=12)
    box("Fridge", 72, 205, 74, 70, 62, "paper_light", z=4.0, bevel=7.0)
    box("FridgeHandle", 108, 205, 5, 26, 4, "amber", z=40.0)
    box("KitchenTable", 280, 150, 110, 66, 22, "wood", z=4.0, bevel=8.0)
    for dx in (-38, 38):
        box("TableLeg", 280 + dx, 150, 8, 44, 22, "carbon", z=4.0)
    cylinder("Kettle", 300, 145, 12, 20, "amber_light", z=26.0)
    box("Notice", 405, 110, 30, 24, 2, "paper_light", z=5.0)


def build_bathroom():
    for x in (760, 860, 960):
        box("Stall", x, 95, 88, 120, 40, "teal_light", z=4.0)
        box("StallDoor", x, 150, 76, 8, 34, "paper", z=6.0)
    for x in (760, 860, 960):
        cylinder("Sink", x, 200, 17, 12, "paper_light", z=4.0)
    box("Bathtub", 1120, 150, 170, 90, 26, "paper_light", z=4.0, bevel=14.0)
    box("Mirror", 1120, 82, 120, 8, 40, "teal_light", z=4.0)


def build_common_room():
    rug("CommonRug", 350, 385, 300, 170, "red")
    box("SofaA", 350, 300, 220, 44, 30, "green", z=5.0, bevel=10.0)
    box("SofaB", 350, 470, 220, 44, 30, "green", z=5.0, bevel=10.0)
    box("CoffeeTable", 350, 385, 110, 58, 18, "wood_light", z=5.0, bevel=8.0)
    box("Shelf", 120, 385, 48, 190, 70, "wood", z=4.0)
    for i in range(4):
        box("ShelfBoard", 120, 315 + i * 46, 42, 6, 5, "paper_light", z=20.0 + i * 12)
    box("Board", 540, 300, 110, 18, 46, "wood", z=4.0)
    for i, mat in enumerate(("paper", "red", "paper_light", "teal", "amber_light")):
        box("BoardNote", 505 + i * 18, 288, 14, 3, 12, mat, z=52.0)
    box("LoungeSofa", 900, 400, 240, 60, 32, "teal", z=5.0, bevel=10.0)
    box("LoungeTable", 900, 320, 100, 44, 18, "wood", z=5.0, bevel=6.0)


def build_hallway():
    for i in range(6):
        box("Locker", 610 + (i % 3) * 34, 190 - (i // 3) * 34, 30, 30, 52, "teal", z=4.0, bevel=3.0)
    box("Noticeboard", 500, 195, 76, 12, 40, "wood", z=4.0)
    for i, mat in enumerate(("paper", "red", "amber_light", "paper_light")):
        box("HallNote", 476 + i * 16, 186, 12, 3, 13, mat, z=46.0)
    box("SecurityCamera", 640, 100, 34, 16, 16, "carbon", z=44.0)
    cylinder("CameraLens", 622, 100, 6, 8, "amber_light", z=52.0, vertices=12)


def build_bedrooms():
    accents = ("teal", "red", "green", "amber", "slate_light", "teal_light")
    for i in range(6):
        x = 140 + i * 200
        accent = accents[i]
        rug("BedroomRug%d" % i, x, 600, 120, 90, accent)
        box("Bed", x - 48, 545, 66, 108, 22, "paper_light", z=5.0, bevel=8.0)
        box("Blanket", x - 48, 570, 62, 58, 5, accent, z=27.0)
        box("Pillow", x - 48, 512, 54, 22, 8, "paper", z=27.0, bevel=4.0)
        box("Desk", x + 52, 528, 64, 34, 22, "wood_light", z=5.0)
        box("Chair", x + 52, 570, 26, 26, 18, "slate_light", z=5.0)
        box("Wardrobe", x + 52, 645, 62, 26, 54, "teal", z=5.0, bevel=4.0)
        cylinder("RoomObject", x - 62, 645, 12, 16, "amber_light", z=5.0)


def build_details():
    for x in range(60, 1240, 80):
        box("FloorSeam", x, 360, 2, 640, 1, "slate_light", z=4.0)
    for y in (60, 140, 220, 300, 380, 460, 540, 620):
        box("FloorCrossSeam", 640, y, 1200, 2, 1, "slate_light", z=4.0)
    box("ExitSign", 520, 92, 86, 10, 26, "green", z=44.0, bevel=3.0)


def area_light(name, location, energy, color, size, target, shadow=False):
    data = bpy.data.lights.new(name, "AREA")
    data.energy = energy
    data.color = color
    data.shape = "DISK"
    data.size = size
    data.use_shadow = shadow
    obj = bpy.data.objects.new(name, data)
    bpy.context.collection.objects.link(obj)
    obj.location = location
    obj.rotation_euler = (Vector(target) - obj.location).to_track_quat("-Z", "Y").to_euler()
    return obj


def sun_light(name, energy, color, tilt_degrees):
    data = bpy.data.lights.new(name, "SUN")
    data.energy = energy
    data.color = color
    data.angle = math.radians(3.0)
    obj = bpy.data.objects.new(name, data)
    bpy.context.collection.objects.link(obj)
    obj.location = (640, 360, 900)
    obj.rotation_euler = (
        math.radians(tilt_degrees),
        math.radians(-18.0),
        math.radians(24.0),
    )
    return obj


def setup(night=False):
    camera_data = bpy.data.cameras.new("DormCamera")
    camera = bpy.data.objects.new("DormCamera", camera_data)
    bpy.context.collection.objects.link(camera)
    camera.location = (640, 360, 1100)
    camera.rotation_euler = (Vector((640, 360, 0)) - camera.location).to_track_quat("-Z", "Y").to_euler()
    camera_data.type = "ORTHO"
    camera_data.ortho_scale = 1280.0
    camera_data.clip_start = 1.0
    camera_data.clip_end = 4000.0
    bpy.context.scene.camera = camera
    world = bpy.data.worlds.get("DormWorld") or bpy.data.worlds.new("DormWorld")
    bpy.context.scene.world = world
    world.use_nodes = True
    bg = world.node_tree.nodes.get("Background")
    if night:
        bg.inputs["Color"].default_value = (0.16, 0.22, 0.34, 1.0)
        bg.inputs["Strength"].default_value = 0.10
    else:
        bg.inputs["Color"].default_value = (0.60, 0.64, 0.68, 1.0)
        bg.inputs["Strength"].default_value = 0.80
    if night:
        sun_light("DormMoon", 0.12, (0.48, 0.62, 0.92), 24.0)
        area_light("WarmHall", (640, 250, 210), 200000.0, (1.0, 0.56, 0.20), 150.0, (640, 250, 0))
        area_light("CommonLamp", (350, 385, 190), 160000.0, (1.0, 0.70, 0.34), 130.0, (350, 385, 0))
        area_light("LoungeLamp", (900, 400, 190), 160000.0, (1.0, 0.64, 0.30), 130.0, (900, 400, 0))
        area_light("KitchenLamp", (150, 120, 180), 140000.0, (0.99, 0.86, 0.58), 120.0, (150, 120, 0))
        area_light("BathLamp", (940, 150, 180), 90000.0, (0.92, 0.96, 1.0), 130.0, (940, 150, 0))
        for i in range(6):
            area_light("BedLamp%d" % i, (140 + i * 200, 585, 150), 90000.0, (1.0, 0.74, 0.40), 80.0, (140 + i * 200, 585, 0))
    else:
        sun_light("DormSun", 4.0, (1.0, 0.92, 0.80), 24.0)
        area_light("WindowWash", (140, 60, 320), 7000.0, (0.86, 0.92, 1.0), 260.0, (140, 60, 0))
        area_light("WarmHall", (640, 250, 240), 3000.0, (1.0, 0.62, 0.26), 200.0, (640, 250, 0))
    return None


def render(path):
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x = 1280
    scene.render.resolution_y = 720
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.film_transparent = False
    scene.render.filepath = path
    try:
        scene.view_settings.view_transform = "Standard"
        scene.view_settings.look = "None"
    except Exception:
        pass
    bpy.ops.render.render(write_still=True)


clear_scene()
build_shell()
build_kitchen()
build_bathroom()
build_common_room()
build_hallway()
build_bedrooms()
build_details()
setup(False)
render(os.path.join(OUT, "archival_dorm_backdrop_day.png"))
clear_scene()
build_shell()
build_kitchen()
build_bathroom()
build_common_room()
build_hallway()
build_bedrooms()
build_details()
setup(True)
render(os.path.join(OUT, "archival_dorm_backdrop_night.png"))
print("Archival dorm backdrops written to", OUT)
