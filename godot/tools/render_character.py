"""
Headless Blender render pipeline: pose + render a Kenney mini-character GLB
into top-down 2D sprite frames (idle-down + 4-directional walk cycle).

Run via:
  blender --background --python render_character.py -- <glb_path> <char_id> <output_dir> [--dirtest]

With --dirtest: renders one idle frame at rotation 0/90/180/270 as
rot_0.png / rot_90.png / rot_180.png / rot_270.png so the direction mapping
can be verified visually before committing to a full render.
"""
import bpy
import sys
import os
import math
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
GLB_PATH = argv[0]
CHAR_ID = argv[1]
OUT_DIR = argv[2]
DIR_TEST = "--dirtest" in argv

WALK_FRAMES = 6
RENDER_SIZE = 256
CAMERA_ELEVATION_DEG = 30.0  # angle above horizontal
CAMERA_DISTANCE = 6.0

def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def import_char(path):
    bpy.ops.import_scene.gltf(filepath=path)
    armature = None
    meshes = []
    extras = []
    for o in bpy.context.scene.objects:
        if o.type == "ARMATURE":
            armature = o
        elif o.type == "MESH":
            has_armature_mod = any(m.type == "ARMATURE" for m in o.modifiers)
            if has_armature_mod:
                meshes.append(o)
            else:
                extras.append(o)
    # drop non-rigged helper objects (e.g. Kenney's "Icosphere" light-probe placeholder)
    for o in extras:
        bpy.data.objects.remove(o, do_unlink=True)
    return armature, meshes

def compute_bounds(meshes):
    min_v = Vector((float("inf"),) * 3)
    max_v = Vector((float("-inf"),) * 3)
    depsgraph = bpy.context.evaluated_depsgraph_get()
    for m in meshes:
        eval_obj = m.evaluated_get(depsgraph)
        for corner in eval_obj.bound_box:
            world_co = eval_obj.matrix_world @ Vector(corner)
            min_v.x, min_v.y, min_v.z = min(min_v.x, world_co.x), min(min_v.y, world_co.y), min(min_v.z, world_co.z)
            max_v.x, max_v.y, max_v.z = max(max_v.x, world_co.x), max(max_v.y, world_co.y), max(max_v.z, world_co.z)
    return min_v, max_v

def setup_world_and_lights():
    scene = bpy.context.scene
    scene.render.film_transparent = True
    scene.render.engine = "BLENDER_EEVEE_NEXT" if "BLENDER_EEVEE_NEXT" in [e.identifier for e in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items] else "BLENDER_EEVEE"
    scene.render.resolution_x = RENDER_SIZE
    scene.render.resolution_y = RENDER_SIZE
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"

    key = bpy.data.objects.new("KeyLight", bpy.data.lights.new("KeyLight", "SUN"))
    key.data.energy = 3.0
    key.rotation_euler = (math.radians(55), 0, math.radians(35))
    bpy.context.collection.objects.link(key)

    fill = bpy.data.objects.new("FillLight", bpy.data.lights.new("FillLight", "SUN"))
    fill.data.energy = 1.2
    fill.rotation_euler = (math.radians(55), 0, math.radians(-145))
    bpy.context.collection.objects.link(fill)

def setup_camera(center, height):
    elev = math.radians(CAMERA_ELEVATION_DEG)
    y = -CAMERA_DISTANCE * math.cos(elev)
    z = center.z + CAMERA_DISTANCE * math.sin(elev)

    cam_data = bpy.data.cameras.new("Cam")
    cam_data.type = "ORTHO"
    cam_data.ortho_scale = height * 1.35
    cam_obj = bpy.data.objects.new("Cam", cam_data)
    cam_obj.location = (center.x, y, z)
    bpy.context.collection.objects.link(cam_obj)
    bpy.context.scene.camera = cam_obj

    target = bpy.data.objects.new("CamTarget", None)
    target.location = center
    bpy.context.collection.objects.link(target)
    con = cam_obj.constraints.new("TRACK_TO")
    con.target = target
    con.track_axis = "TRACK_NEGATIVE_Z"
    con.up_axis = "UP_Y"
    return cam_obj

def set_action(armature, name):
    if armature.animation_data is None:
        armature.animation_data_create()
    action = bpy.data.actions.get(name)
    if action is None:
        raise RuntimeError(f"action '{name}' not found; available: {[a.name for a in bpy.data.actions]}")
    armature.animation_data.action = action
    return action

def render_frame(path):
    bpy.context.scene.render.filepath = path
    bpy.ops.render.render(write_still=True)

def main():
    reset_scene()
    armature, meshes = import_char(GLB_PATH)
    if armature is None:
        raise RuntimeError("no armature found in import")

    armature.rotation_mode = "XYZ"

    min_v, max_v = compute_bounds(meshes)
    height = max_v.z - min_v.z
    center = Vector(((min_v.x + max_v.x) / 2, (min_v.y + max_v.y) / 2, (min_v.z + max_v.z) / 2))
    print(f"BOUNDS min={tuple(min_v)} max={tuple(max_v)} height={height} center={tuple(center)}")

    setup_world_and_lights()
    setup_camera(center, height)

    os.makedirs(OUT_DIR, exist_ok=True)

    if DIR_TEST:
        set_action(armature, "idle")
        bpy.context.scene.frame_set(0)
        for rot_deg in (0, 90, 180, 270):
            armature.rotation_euler = (0, 0, math.radians(rot_deg))
            bpy.context.view_layer.update()
            print(f"rot_deg={rot_deg} armature.rotation_euler={tuple(armature.rotation_euler)} matrix_world_euler={tuple(armature.matrix_world.to_euler())}")
            render_frame(os.path.join(OUT_DIR, f"rot_{rot_deg}.png"))
        print("DIRTEST_DONE")
        return

    # direction -> Z rotation determined empirically via --dirtest pass
    directions = {
        "down": 0,
        "right": 90,
        "up": 180,
        "left": 270,
    }

    # idle (facing down only)
    set_action(armature, "idle")
    armature.rotation_euler = (0, 0, math.radians(directions["down"]))
    idle_dir = os.path.join(OUT_DIR, "idle_down")
    os.makedirs(idle_dir, exist_ok=True)
    bpy.context.scene.frame_set(0)
    render_frame(os.path.join(idle_dir, "frame_0.png"))

    # walk cycle, 4 directions
    walk_action = set_action(armature, "walk")
    frame_start, frame_end = walk_action.frame_range
    for dir_name, rot_deg in directions.items():
        armature.rotation_euler = (0, 0, math.radians(rot_deg))
        out_dir = os.path.join(OUT_DIR, f"walk_{dir_name}")
        os.makedirs(out_dir, exist_ok=True)
        for i in range(WALK_FRAMES):
            t = frame_start + (frame_end - frame_start) * (i / WALK_FRAMES)
            bpy.context.scene.frame_set(int(round(t)))
            render_frame(os.path.join(out_dir, f"frame_{i}.png"))

    print("RENDER_DONE")

main()
