import bpy
import os

# Clear existing mesh objects
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)

# Create ground
bpy.ops.mesh.primitive_plane_add(size=120, location=(0, 0, 0))
ground = bpy.context.active_object
ground.name = "ground"

# Create walls
wall_thickness = 2
wall_height = 6
arena_size = 60

def create_wall(name, loc, scale):
    bpy.ops.mesh.primitive_cube_add(location=loc)
    wall = bpy.context.active_object
    wall.name = name
    wall.scale = scale
    return wall

# North wall
create_wall("wall_n", (0, -arena_size, wall_height/2), (arena_size, wall_thickness/2, wall_height/2))
# South wall
create_wall("wall_s", (0, arena_size, wall_height/2), (arena_size, wall_thickness/2, wall_height/2))
# East wall
create_wall("wall_e", (arena_size, 0, wall_height/2), (wall_thickness/2, arena_size, wall_height/2))
# West wall
create_wall("wall_w", (-arena_size, 0, wall_height/2), (wall_thickness/2, arena_size, wall_height/2))

# Create cover blocks
cover_positions = [
    (-20, -20), (20, -20),
    (-20, 20), (20, 20),
    (0, 0)
]
for i, pos in enumerate(cover_positions):
    bpy.ops.mesh.primitive_cube_add(location=(pos[0], pos[1], 1))
    box = bpy.context.active_object
    box.name = f"cover_{i}"
    box.scale = (1, 1, 1)

# Create ramps
bpy.ops.mesh.primitive_cube_add(location=(-35, 0, 1))
ramp1 = bpy.context.active_object
ramp1.name = "ramp1"
ramp1.rotation_euler = (0, 0, 0.785)
ramp1.scale = (1, 1, 1)

bpy.ops.mesh.primitive_cube_add(location=(35, 0, 1))
ramp2 = bpy.context.active_object
ramp2.name = "ramp2"
ramp2.rotation_euler = (0, 0, -0.785)
ramp2.scale = (1, 1, 1)

# Export as FBX
output_path = os.path.join(os.path.dirname(bpy.data.filepath), "arena_map.fbx")
bpy.ops.export_scene.fbx(filepath=output_path, use_selection=False)
print(f"Map exported to: {output_path}")
