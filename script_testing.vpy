from vstools import core, set_output
import vsdeinterlace
from vs_helpers import resize_jetpack_ar
from vsrgtools import unsharpen, soothe
from vsdenoise import ccd, mc_degrain, Prefilter, MVToolsPreset
from dfttest2 import Backend
import os

core.num_threads = 16
core.max_cache_size = 8096

# Import the video
SOURCE = os.environ.get("SOURCE_FILE")

if not SOURCE:
    raise RuntimeError(
        "SOURCE_FILE is not set. Pass it from the .bat file or set it as an environment variable."
    )

clip = core.bs.VideoSource(SOURCE, showprogress=False)

# Take a specific part of video
clip_cut = clip[38612:81771]

# Crop black borders
clip_crop = core.std.CropRel(clip_cut, 10, 10, 0, 0)
# add_border = clip_cut.std.AddBorders(top=2, left=2)

# Deinterlacing
field_order = core.std.SetFieldBased(clip_crop, 2) # 1=BFF, 2=TFF
deinterlaced = vsdeinterlace.QTempGaussMC(field_order).deinterlace()

# Chroma noise reduction
chroma_fix = ccd(
    deinterlaced,
    thr=6,
    tr=1
)

# General denoising (Including chroma)
denoised = mc_degrain(
    deinterlaced,
    prefilter=Prefilter.DFTTEST(
        backend=Backend.NVRTC(device_id=0, num_streams=2)
    ),
    preset=MVToolsPreset.HQ_SAD,
    tr=1,
    thsad=200
)

# Very light luma-only sharpening

sharp = unsharpen(
    denoised,
    strength=0.30,
    planes=0
)

# Reduce temporal instability / shimmering caused by sharpening
sharp_soothe = soothe(
    sharp,
    denoised,
    temporal_strength=0.35,
    spatial_strength=0.0,
    planes=0
)

# Resize
resized = resize_jetpack_ar(sharp_soothe, height=1440, dar="4/3")



set_output(clip_crop, "Source")
set_output(deinterlaced, "Deinterlaced")
set_output(chroma_fix, "Chroma")
set_output(denoised, "Denoised")
set_output(sharp_soothe, "Sharpened")
set_output(resized, "Rezised")
