import bpy
import os

# Clear existing mesh objects
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)

# Create body (capsule-like using cylinder with rounded edges or just cylinder)
bpy.ops.mesh.primitive_cylinder_add(radius=0.35, depth=0.8, location=(0, 0, 1.0))
body = bpy.context.active_object
body.name = "robot_body"

# Create head
bpy.ops.mesh.primitive_cube_add(size=0.4, location=(0, 0, 1.6))
head = bpy.context.active_object
head.name = "robot_head"

# Create weapon
bpy.ops.mesh.primitive_cube_add(location=(0.25, 0.3, 1.3))
weapon = bpy.context.active_object
weapon.name = "robot_weapon"
weapon.scale = (0.04, 0.125, 0.3)

# Create muzzle point (empty for reference)
bpy.ops.object.empty_add(type='PLAIN_AXES', location=(0.25, 0.0, 1.0))
muzzle = bpy.context.active_object
muzzle.name = "muzzle"

# Join all parts into a single object for easy export
# First select all mesh objects
for obj in bpy.data.objects:
    if obj.type == 'MESH':
        obj.select_set(True)
    else:
        obj.select_set(False)

# Set body as active
bpy.context.view_layer.objects.active = body

# Export as FBX
output_path = os.path.join(os.path.dirname(bpy.data.filepath), "robot.fbx")
bpy.ops.export_scene.fbx(filepath=output_path, use_selection=False)
print(f"Robot exported to: {output_path}")
