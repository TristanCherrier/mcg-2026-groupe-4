import bpy
import os


PROJECT_ROOT = "/Users/sabyhislam/Downloads/UBE_Campus_Quest"
IMPORTS = os.path.join(PROJECT_ROOT, "Imports")
OUTPUT = os.path.join(PROJECT_ROOT, "Assets", "mission_campus_assets.blend")


ASSETS = [
    ("Classroom", os.path.join(IMPORTS, "Classroom", "classroom.glb"), (-6.0, 0.0, 0.0)),
    ("Robot", os.path.join(IMPORTS, "robot_body.glb"), (0.0, 0.0, 0.0)),
    ("Car", os.path.join(IMPORTS, "TinyCar_Chassis.glb"), (6.0, 0.0, 0.0)),
    ("Ship", os.path.join(IMPORTS, "ship_frame.glb"), (12.0, 0.0, 0.0)),
]


def relink_selected_to_collection(collection_name, offset):
    collection = bpy.data.collections.new(collection_name)
    bpy.context.scene.collection.children.link(collection)
    selected = list(bpy.context.selected_objects)
    for obj in selected:
        for user_collection in list(obj.users_collection):
            user_collection.objects.unlink(obj)
        collection.objects.link(obj)
        obj.location.x += offset[0]
        obj.location.y += offset[1]
        obj.location.z += offset[2]


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.scene.unit_settings.system = "METRIC"

    for collection_name, filepath, offset in ASSETS:
        if os.path.exists(filepath):
            bpy.ops.import_scene.gltf(filepath=filepath)
            relink_selected_to_collection(collection_name, offset)

    bpy.ops.file.make_paths_relative()
    bpy.ops.wm.save_as_mainfile(filepath=OUTPUT)


if __name__ == "__main__":
    main()
