from vstools import core, set_output
import vsdeinterlace
from vs_helpers import resize_jetpack_ar
from vsrgtools import unsharpen, soothe

core.num_threads = 16
core.max_cache_size = 8096

clip = core.bs.VideoSource("G:/VHS-presnimavanja/vhsdecode-gems/tvsa-epp-1988_export.mkv", showprogress=True)

# Crop black borders
# LEFT, RIGHT, TOP, BOTTOM
clip_crop = core.std.CropRel(clip, 0, 0, 0, 0)
# add_border = clip_crop.std.AddBorders(top=1, left=2)

clip_cut = clip_crop[0:20]

# Deinterlacing
field_order = core.std.SetFieldBased(clip_crop, 2) # 1=BFF, 2=TFF
deinterlaced = vsdeinterlace.QTempGaussMC(
    # Keep accurate motion analysis
    analyze_blksize=16,
    analyze_overlap=2,
    analyze_refine=2,

    # Keep stronger temporal processing
    basic_tr=2,
    final_tr=2,

    motion_blur_fps_divisor=1
).deinterlace(field_order)

# Resize
resized = resize_jetpack_ar(deinterlaced, height=960, dar="3/2")


set_output(clip, "Source")
set_output(deinterlaced, "Deinterlaced")
set_output(resized, "Resized")