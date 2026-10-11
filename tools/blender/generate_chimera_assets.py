"""Project Chimera low-poly dorm asset generator.
Run in Blender 4.x. Generates reusable furniture/evidence props and exports GLB files.
Also creates a small orthographic showcase scene so the same assets can be rendered as sprites.
"""
import bpy, os, math
from mathutils import Vector

ROOT = bpy.path.abspath('//')
OUT = os.path.abspath(os.path.join(ROOT, '..', '..', 'godot', 'assets', '3d', 'dorm'))
os.makedirs(OUT, exist_ok=True)

COLORS = {
    'wood': (0.40, 0.24, 0.12, 1), 'wood2': (0.62, 0.40, 0.20, 1),
    'fabric': (0.29, 0.34, 0.42, 1), 'metal': (0.30, 0.34, 0.38, 1),
    'paper': (0.76, 0.70, 0.55, 1), 'blue': (0.22, 0.40, 0.62, 1),
    'green': (0.25, 0.48, 0.30, 1), 'red': (0.55, 0.20, 0.20, 1),
    'cream': (0.72, 0.64, 0.47, 1),
}

def clear():
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)


def material(name):
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    m.diffuse_color = COLORS[name]
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get('Principled BSDF')
    bsdf.inputs['Base Color'].default_value = COLORS[name]
    bsdf.inputs['Roughness'].default_value = 0.78
    return m


def cube(name, loc, scale, mat):
    bpy.ops.mesh.primitive_cube_add(location=loc)
    o = bpy.context.object; o.name = name; o.scale = (scale[0]/2, scale[1]/2, scale[2]/2)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    o.data.materials.append(material(mat)); return o


def cyl(name, loc, radius, depth, mat, vertices=12):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=loc)
    o=bpy.context.object; o.name=name; o.data.materials.append(material(mat)); return o


def join_export(name):
    bpy.ops.object.select_all(action='DESELECT')
    objs=[o for o in bpy.context.scene.objects if o.type=='MESH']
    for o in objs: o.select_set(True)
    bpy.context.view_layer.objects.active=objs[0]
    bpy.ops.object.join()
    root=bpy.context.object; root.name=name
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    path=os.path.join(OUT, name+'.glb')
    bpy.ops.export_scene.gltf(filepath=path, export_format='GLB', use_selection=True, export_apply=True)
    bpy.data.objects.remove(root, do_unlink=True)


def bed():
    cube('frame',(0,0,0.8),(2.6,2.1,.25),'wood')
    cube('mattress',(0,0,1.03),(2.35,1.8,.22),'fabric')
    cube('headboard',(0,.95,1.25),(2.5,.22,1.35),'wood')
    cube('pillow',(0,-.45,1.18),(2.2,.6,.15),'cream')
    join_export('bed')


def desk():
    cube('top',(0,0,1.35),(2.8,1.35,.18),'wood')
    for x in (-1.15,1.15): cube('leg',(x,0,.67),(.18,1.05,1.35),'wood2')
    cube('back',(0,.5,1.05),(2,.12,.45),'wood2')
    cube('laptop',(0,0,1.49),(.9,.6,.08),'blue')
    cube('paper',(.65,0,1.49),(.45,.28,.08),'paper')
    join_export('desk')


def chair():
    cube('seat',(0,0,1),(1,.9,.16),'wood2')
    cube('back',(0,.32,1.48),(.85,.14,1.1),'wood2')
    for x in (-.38,.38):
        for y in (-.32,.32): cyl('leg',(x,y,.5),.08,1,'metal')
    join_export('chair')


def bookshelf():
    cube('body',(0,0,1.6),(2,.55,3.2),'wood')
    for z in (.65,1.25,1.85,2.45): cube('shelf',(0,0,z),(1.75,.48,.08),'wood2')
    for i,(x,c) in enumerate([(-.65,'red'),(-.25,'green'),(.15,'blue'),(.55,'cream')]): cube('book',(x,-.04,2.72),(.28,.38,.42),c)
    join_export('bookshelf')


def locker():
    cube('body',(0,0,1.45),(1.5,.7,2.9),'metal')
    for x in (-.35,.35):
        cube('door',(x,-.37,1.48),(.55,.03,2.5),'blue')
        cyl('handle',(x,-.43,1.5),.05,.12,'metal',12)
    join_export('locker')


def lamp():
    cyl('stem',(0,0,.7),.12,1.4,'metal')
    cyl('shade',(0,0,1.48),.55,.35,'cream',12)
    cyl('rim',(0,0,1.65),.75,.12,'wood2',12)
    join_export('lamp')


def trash_bin():
    cyl('bin',(0,0,.5),.55,1.0,'metal',12)
    cyl('rim',(0,0,1.02),.60,.08,'wood2',12)
    join_export('trash_bin')


def evidence_board():
    cube('board',(0,0,1.1),(2.8,.15,2.2),'wood')
    for x,z,c in [(-.7,1.6,'paper'),(.55,1.7,'red'),(-.3,.75,'cream'),(.7,.7,'blue')]: cube('note',(x,-.11,z),(.7,.06,.45),c)
    join_export('evidence_board')


def suitcase():
    cube('case',(0,0,.4),(1.5,.9,.5),'red')
    cube('latch',(0,-.5,.42),(1.15,.06,.38),'metal')
    cyl('handle',(0,0,.85),.07,.45,'metal')
    join_export('suitcase')



def rounded_box(name, loc, scale, mat, bevel=0.12):
    o = cube(name, loc, scale, mat)
    mod = o.modifiers.new('SoftEdges', 'BEVEL')
    mod.width = bevel
    mod.segments = 2
    bpy.context.view_layer.objects.active = o
    bpy.ops.object.modifier_apply(modifier=mod.name)
    return o


def couch():
    rounded_box('base',(0,0,.55),(3.6,1.7,1.0),'fabric',.18)
    rounded_box('back',(0,.48,1.35),(3.5,.35,1.5),'fabric',.16)
    for x in (-1.25,1.25): rounded_box('arm',(x,0,1.12),(.55,1.65,1.35),'fabric',.12)
    join_export('couch')


def noticeboard():
    cube('board',(0,0,1.25),(3.2,.18,2.4),'wood')
    for x,z,c in [(-.9,1.8,'paper'),(.15,1.75,'cream'),(1.0,1.85,'red'),(-.55,.85,'blue'),(.65,.72,'green')]:
        cube('note',(x,-.12,z),(.7,.08,.48),c)
    join_export('noticeboard')


def vending():
    rounded_box('body',(0,0,1.6),(1.9,.85,3.2),'metal',.08)
    cube('screen',(0,-.44,2.05),(1.1,.08,.9),'blue')
    for z in (1.05,1.35,1.65): cube('slot',(0,-.46,z),(1.2,.05,.08),'cream')
    join_export('vending')


def server_rack():
    rounded_box('rack',(0,0,1.6),(1.6,.8,3.3),'metal',.08)
    for z in (.65,1.15,1.65,2.15,2.65):
        cube('server',(0,-.44,z),(1.25,.08,.32),'blue')
        cyl('led',(-.5,-.5,z),.045,.08,'green')
    join_export('server_rack')


def terminal():
    rounded_box('screen',(0,0,1.65),(2.3,.45,1.6),'metal',.1)
    cube('display',(0,-.26,1.8),(1.7,.06,1.0),'blue')
    cube('base',(0,.08,.6),(1.0,.8,.25),'metal')
    join_export('terminal')


def hospital_cart():
    rounded_box('cabinet',(0,0,1.0),(2.2,.85,1.7),'metal',.08)
    for z in (.55,1.05,1.55): cube('drawer',(0,-.46,z),(1.75,.06,.28),'cream')
    for x in (-.8,.8): cyl('wheel',(x,0,.22),.16,.24,'metal')
    join_export('hospital_cart')


def bar_booth():
    rounded_box('seat',(0,0,.72),(3.2,1.65,1.0),'fabric',.18)
    rounded_box('back',(0,.55,1.45),(3.2,.35,1.5),'fabric',.16)
    cube('table',(0,-.12,1.32),(2.3,1.0,.16),'wood2')
    join_export('bar_booth')


def counter():
    rounded_box('base',(0,0,.9),(3.5,1.1,1.8),'wood',.08)
    cube('top',(0,0,1.9),(3.7,1.25,.18),'wood2')
    join_export('counter')


def lab_easel():
    cube('canvas',(0,0,1.7),(2.3,.15,2.2),'paper')
    for x in (-.8,.8): cyl('leg',(x,0,.65),.08,2.1,'wood2')
    cyl('center',(0,0,.95),.08,1.7,'wood2')
    join_export('lab_easel')


def courtyard_tree():
    cyl('trunk',(0,0,.8),.28,1.6,'wood2')
    cyl('crown',(0,0,2.0),1.0,1.2,'green',12)
    join_export('courtyard_tree')

def security_camera():
    cube('mount',(0,0,.2),(.5,.35,.35),'metal')
    bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=.22, depth=.42, location=(0,-.15,.2), rotation=(0,math.pi/2,0))
    bpy.context.object.data.materials.append(material('metal'))
    bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=.10, depth=.08, location=(0,-.38,.2), rotation=(0,math.pi/2,0))
    bpy.context.object.data.materials.append(material('blue'))
    join_export('security_camera')


clear()
for fn in (bed,desk,chair,bookshelf,locker,lamp,trash_bin,evidence_board,suitcase,security_camera,couch,noticeboard,vending,server_rack,terminal,hospital_cart,bar_booth,counter,lab_easel,courtyard_tree):
    fn(); clear()
print('Project Chimera assets exported to', OUT)
