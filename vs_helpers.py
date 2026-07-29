from fractions import Fraction
from vskernels import Spline36, Lanczos


def round_to_mod(value: float, mod: int = 2) -> int:
    return int(round(value / mod) * mod)


def parse_dar(dar) -> float:
    """
    Accepts:
        "4:3"
        "4/3"
        "16:9"
        "16/9"
        1.333333
    """
    if isinstance(dar, (int, float)):
        return float(dar)

    dar = str(dar).strip()

    if ":" in dar:
        w, h = dar.split(":")
        return float(Fraction(int(w), int(h)))

    return float(Fraction(dar))


def resize_jetpack_ar(clip, width=None, height=None, dar="4:3", mod=2, scaler=None):
    """
    Resize with vs-jetpack/vskernels while calculating the missing dimension.

    Example:
        resize_jetpack_ar(clip, height=576, dar="4:3")   -> 768x576
        resize_jetpack_ar(clip, height=1440, dar="4:3")  -> 1920x1440
    """

    if scaler is None:
        scaler = Lanczos()

    if (width is None and height is None) or (width is not None and height is not None):
        raise ValueError("Set exactly one of width or height.")

    ratio = parse_dar(dar)

    if width is None:
        width = round_to_mod(height * ratio, mod)
    else:
        height = round_to_mod(width / ratio, mod)

    print(f"Resizing with {scaler.__class__.__name__}: {width}x{height}")

    return scaler.scale(clip, width=width, height=height)