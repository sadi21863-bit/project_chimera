import bpy
import os
from mathutils import Vector

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "godot", "assets", "prototypes")
os.makedirs(OUT, exist_ok=True)

COLORS = {
    "carbon": (0.035, 0.055, 0.075, 1.0),
    "slate": (0.12, 0.19, 0.23, 1.0),
    "slate_light": (0.22, 0.31, 0.34, 1.0),
    "paper": (0.72, 0.68, 0.58, 1.0),
    "paper_light": (0.86, 0.82, 0.70, 1.0),
    "green": (0.19, 0.32, 0.27, 1.0),
    "green_light": (0.31, 0.46, 0.37, 1.0),
    "amber": (0.78, 0.36, 0.08, 1.0),
    "amber_light": (1.0, 0.55, 0.16, 1.0),
    "red": (0.48, 0.10, 0.09, 1.0),
    "teal": (0.12, 0.30, 0.32, 1.0),
    "metal": (0.32, 0.37, 0.38, 1.0),
    "wood": (0.30, 0.18, 0.10, 1.0),
    "black": (0.008, 0.012, 0.016, 1.0),
}


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for data in (bpy.data.meshes, bpy.data.materials, bpy.data.cameras, bpy.data.lights):
        for item in list(data):
            if item.users == 0:
                data.remove(item)


def make_material(name, color, roughness=0.8, emission=0.0):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.diffuse_color = color
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = color
    bsdf.inputs["Roughness"].default_value = roughness
    if emission > 0.0:
        if "Emission Color" in bsdf.inputs:
            bsdf.inputs["Emission Color"].default_value = color
        if "Emission Strength" in bsdf.inputs:
            bsdf.inputs["Emission Strength"].default_value = emission
    return mat


def box(name, location, dimensions, material, bevel=0.0):
    bpy.ops.mesh.primitive_cube_add(location=location)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = dimensions
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(make_material(material, COLORS[material]))
    if bevel > 0.0:
        mod = obj.modifiers.new("EdgeSoftener", "BEVEL")
        mod.width = bevel
        mod.segments = 2
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.modifier_apply(modifier=mod.name)
    return obj


def cylinder(name, location, radius, depth, material, vertices=16):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(make_material(material, COLORS[material]))
    return obj


def area_light(name, location, energy, color, size, target):
    data = bpy.data.lights.new(name, "AREA")
    data.energy = energy
    data.color = color
    data.shape = "DISK"
    data.size = size
    obj = bpy.data.objects.new(name, data)
    bpy.context.collection.objects.link(obj)
    obj.location = location
    obj.rotation_euler = (Vector(target) - obj.location).to_track_quat("-Z", "Y").to_euler()
    return obj


def build_room():
    box("Floor", (0, 0, -0.18), (12.8, 7.4, 0.36), "slate", 0.04)
    box("FloorInset", (0, -0.02, 0.02), (12.2, 6.8, 0.05), "green", 0.02)
    box("BackWall", (0, 3.35, 2.25), (12.8, 0.22, 4.6), "slate_light", 0.03)
    box("LeftWall", (-6.25, 0, 2.25), (0.22, 6.7, 4.6), "slate", 0.03)
    box("RightWall", (6.25, 0, 1.55), (0.22, 6.7, 3.2), "slate", 0.03)
    box("HallOpening", (3.85, 3.22, 1.3), (2.1, 0.12, 2.6), "carbon", 0.02)
    box("KitchenBack", (-3.65, 3.18, 1.1), (5.1, 0.14, 2.2), "paper", 0.02)
    box("KitchenCounter", (-3.55, 1.75, 0.72), (4.8, 1.05, 1.35), "teal", 0.06)
    box("CounterTop", (-3.55, 1.75, 1.46), (5.0, 1.18, 0.14), "metal", 0.03)
    box("Sink", (-3.9, 1.62, 1.55), (1.15, 0.62, 0.08), "slate_light", 0.04)
    box("CounterDivider", (-2.35, 1.74, 1.56), (0.08, 0.8, 0.04), "carbon")
    for x in (-5.1, -4.25, -3.4, -2.55):
        box("CabinetDoor", (x, 1.18, 0.74), (0.72, 0.06, 1.12), "green_light", 0.02)
        cylinder("CabinetHandle", (x, 1.12, 0.86), 0.035, 0.05, "amber_light", 10)
    box("Fridge", (-5.35, 0.2, 1.38), (1.25, 1.25, 2.65), "paper_light", 0.08)
    box("FridgeShadow", (-5.35, -0.45, 1.38), (1.05, 0.04, 2.35), "slate_light", 0.02)
    box("FridgeHandle", (-4.86, -0.49, 1.45), (0.06, 0.06, 0.72), "amber", 0.02)
    box("DiningTable", (-1.2, -1.3, 0.86), (2.7, 1.25, 0.16), "wood", 0.05)
    for x in (-2.25, -0.15):
        for y in (-1.78, -0.82):
            box("TableLeg", (x, y, 0.42), (0.12, 0.12, 0.82), "carbon")
    box("Noticeboard", (1.0, 3.18, 2.0), (2.6, 0.12, 1.8), "wood", 0.03)
    for x, z, material in ((0.25, 2.35, "paper"), (1.05, 2.2, "red"), (1.85, 2.4, "paper_light"), (0.55, 1.6, "amber_light"), (1.55, 1.55, "teal")):
        box("Notice", (x, 3.10, z), (0.5, 0.025, 0.38), material)
    box("LockerBank", (4.75, 2.78, 1.25), (2.5, 0.7, 2.5), "metal", 0.04)
    for x in (4.15, 4.85, 5.55):
        box("LockerDoor", (x, 2.39, 1.25), (0.62, 0.04, 2.25), "teal", 0.02)
        box("LockerSlot", (x, 2.35, 1.85), (0.28, 0.03, 0.08), "carbon")
    box("CameraMount", (4.1, 3.05, 3.35), (0.5, 0.18, 0.18), "carbon", 0.02)
    box("CameraBody", (4.1, 2.88, 3.28), (0.55, 0.35, 0.22), "slate_light", 0.04)
    cylinder("CameraLens", (3.8, 2.68, 3.28), 0.09, 0.08, "amber_light", 12)
    box("EvidenceTable", (1.0, -1.25, 0.78), (1.8, 0.9, 0.12), "paper_light", 0.03)
    for x in (0.35, 1.65):
        box("EvidenceLeg", (x, -1.25, 0.38), (0.1, 0.1, 0.72), "carbon")
    box("EvidenceFolder", (0.8, -1.25, 0.87), (0.9, 0.58, 0.035), "red", 0.01)
    cylinder("EvidenceBottle", (1.25, -1.25, 1.02), 0.12, 0.3, "amber_light", 12)
    box("EvidenceCap", (1.25, -1.25, 1.2), (0.14, 0.14, 0.08), "carbon", 0.01)
    for x in (-4.9, -3.0, -1.1, 0.8, 2.7, 4.6):
        box("FloorSeam", (x, 0, 0.06), (0.025, 6.4, 0.012), "slate_light")


def setup_camera():
    camera_data = bpy.data.cameras.new("ArchivalCamera")
    camera = bpy.data.objects.new("ArchivalCamera", camera_data)
    bpy.context.collection.objects.link(camera)
    camera.location = (8.8, -11.5, 8.4)
    target = Vector((0.0, 0.0, 1.0))
    camera.rotation_euler = (target - camera.location).to_track_quat("-Z", "Y").to_euler()
    camera_data.type = "ORTHO"
    camera_data.ortho_scale = 10.8
    camera_data.lens = 50
    bpy.context.scene.camera = camera


def setup_world(night=False):
    world = bpy.data.worlds.get("ArchivalWorld") or bpy.data.worlds.new("ArchivalWorld")
    bpy.context.scene.world = world
    world.use_nodes = True
    background = world.node_tree.nodes.get("Background")
    background.inputs["Color"].default_value = (0.018, 0.028, 0.045, 1.0) if night else (0.10, 0.14, 0.17, 1.0)
    background.inputs["Strength"].default_value = 0.32 if night else 0.65
    key_energy = 650.0 if night else 950.0
    fill_energy = 280.0 if night else 500.0
    area_light("Key", (-4.0, -4.5, 8.0), key_energy, (1.0, 0.72, 0.48) if not night else (0.48, 0.62, 1.0), 5.0, (0, 0, 0))
    area_light("Fill", (5.0, -1.0, 6.0), fill_energy, (0.45, 0.65, 0.85), 4.0, (0, 0, 1))
    area_light("Kitchen practical", (-3.5, 0.5, 4.6), 180.0 if not night else 260.0, (1.0, 0.35, 0.08), 2.0, (-3.5, 0.5, 0))
    area_light("Hall practical", (3.0, 1.5, 4.2), 120.0 if not night else 220.0, (1.0, 0.48, 0.12), 1.5, (3.0, 1.5, 0))


def export_glb(path):
    bpy.ops.object.select_all(action="DESELECT")
    for obj in bpy.context.scene.objects:
        if obj.type in {"MESH", "EMPTY"}:
            obj.select_set(True)
    if bpy.context.selected_objects:
        bpy.context.view_layer.objects.active = bpy.context.selected_objects[0]
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", use_selection=True, export_apply=True)


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
        scene.view_settings.view_transform = "AgX"
        scene.view_settings.look = "AgX - Medium High Contrast"
    except Exception:
        pass
    bpy.ops.render.render(write_still=True)


clear_scene()
build_room()
setup_camera()
setup_world(False)
export_glb(os.path.join(OUT, "archival_cutaway_room.glb"))
render(os.path.join(OUT, "archival_cutaway_room_day.png"))
clear_scene()
build_room()
setup_camera()
setup_world(True)
render(os.path.join(OUT, "archival_cutaway_room_night.png"))
print("Archival Cutaway renders written to", OUT)
