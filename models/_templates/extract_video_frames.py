import bpy
import json
import os

vdir = r"c:\Users\Sarah\Desktop\Nerf_mapinguari\pls_nerf_mapinguari-main\art\videos\mae_dagua"
fdir = os.path.join(vdir, "frames")
os.makedirs(fdir, exist_ok=True)

videos = ["qSR-qK2vRQY", "O6HQhs-gk50", "m-Obo_nC3SM"]

for vid in videos:
    info_path = os.path.join(vdir, f"{vid}.info.json")
    if os.path.exists(info_path):
        with open(info_path, "r", encoding="utf-8") as f:
            info = json.load(f)
        print(f"=== {vid}: {info.get('title')} (duration: {info.get('duration')}s) ===")
        chapters = info.get("chapters") or []
        for ch in chapters:
            print(f"  Chapter {ch.get('start_time')}s - {ch.get('end_time')}s: {ch.get('title')}")

    mp4_path = os.path.join(vdir, f"{vid}.mp4")
    if not os.path.exists(mp4_path):
        continue

    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    if not scene.sequence_editor:
        scene.sequence_editor_create()
    seq = scene.sequence_editor
    strip = seq.strips.new_movie(name=vid, filepath=mp4_path, channel=1, frame_start=1)
    fps = scene.render.fps
    total_frames = strip.frame_final_duration
    scene.render.resolution_x = 640
    scene.render.resolution_y = 360
    scene.render.image_settings.file_format = 'JPEG'
    scene.render.image_settings.quality = 85

    # Extract 6 representative frames across the video
    num_samples = 6
    step = max(1, total_frames // (num_samples + 1))
    for i in range(1, num_samples + 1):
        frame_num = i * step
        sec = int(frame_num / fps)
        mm, ss = divmod(sec, 60)
        scene.frame_set(frame_num)
        out_file = os.path.join(fdir, f"{vid}_f{i:02d}_{mm:02d}m{ss:02d}s.jpg")
        scene.render.filepath = out_file
        bpy.ops.render.render(write_still=True)
        print(f"  Saved frame: {os.path.basename(out_file)}")

