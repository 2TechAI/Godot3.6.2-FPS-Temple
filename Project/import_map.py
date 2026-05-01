import bpy
import os

# 清除默认场景
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete()

# 地图文件路径
map_path = r"e:\Godot-Engine-FPS-master\Project\data\models\arena_map.fbx"

# 导入FBX
bpy.ops.import_scene.fbx(filepath=map_path)

# 输出位置
output_dir = r"e:\Godot-Engine-FPS-master\Project\data\models\map"
os.makedirs(output_dir, exist_ok=True)

# 导出为gltf
output_path = os.path.join(output_dir, "de_dust2.gltf")
bpy.ops.export_scene.gltf(filepath=output_path, export_format='GLB')

print(f"地图已导出到: {output_path}")
print("完成！现在你可以在Godot中加载这个地图了")
