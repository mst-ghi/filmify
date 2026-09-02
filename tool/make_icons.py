#!/usr/bin/env python3
"""Generate the Filmify launcher icon set.

Design: rounded-corner square, purple diagonal gradient, centered white "F"
monogram (DejaVu Sans Bold), green accent dot at the F's terminal. Sizes:
Android mipmaps, Linux 512/256/128/64/48/32, Windows ico (256/128/64/48/32/16).
"""
from PIL import Image, ImageDraw, ImageFont
import os

REPO = '/home/mostafa/Workspace/x-archive/filmify'
FONT = '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'

# Brand palette (app_theme.dart): purple ramp + green accent.
PURPLE_TOP = (168, 85, 247)     # purpleBright
PURPLE_BOT = (126, 34, 206)     # purpleDim
GREEN = (74, 222, 128)          # greenBright
WHITE = (255, 255, 255)

MASTER = 1024
CORNER = int(MASTER * 0.22)     # squircle-ish radius


def base_tile(size: int) -> Image.Image:
    """Rounded square with a diagonal purple gradient."""
    scale = size / MASTER
    corner = int(CORNER * scale)
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    grad = Image.new('RGBA', (size, size))
    top, bot = PURPLE_TOP, PURPLE_BOT
    px = grad.load()
    for y in range(size):
        for x in range(size):
            t = (x + y) / (2 * size - 1) if size > 1 else 0
            px[x, y] = (
                int(top[0] + (bot[0] - top[0]) * t),
                int(top[1] + (bot[1] - top[1]) * t),
                int(top[2] + (bot[2] - top[2]) * t),
                255,
            )
    mask = Image.new('L', (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [0, 0, size - 1, size - 1], radius=corner, fill=255)
    img.paste(grad, (0, 0), mask)
    return img


def draw_monogram(img: Image.Image) -> None:
    """Centered white F + green dot, drawn relative to the canvas size."""
    size = img.width
    d = ImageDraw.Draw(img)
    font = ImageFont.truetype(FONT, int(size * 0.52))
    bbox = d.textbbox((0, 0), 'F', font=font)
    w, h = bbox[2] - bbox[0], bbox[3] - bbox[1]
    x = (size - w) / 2 - bbox[0]
    y = (size - h) / 2 - bbox[1]
    d.text((x, y), 'F', font=font, fill=WHITE)
    # Green dot tucked at the bottom-right of the F stem.
    dot_r = size * 0.055
    dot_cx = x + bbox[0] + w + dot_r * 0.7
    dot_cy = y + bbox[1] + h - dot_r * 0.6
    d.ellipse(
        [dot_cx - dot_r, dot_cy - dot_r, dot_cx + dot_r, dot_cy + dot_r],
        fill=GREEN)




def write_adaptive_android(master: Image.Image) -> None:
    """Adaptive icon: full-bleed gradient background + 66% foreground."""
    res = f'{REPO}/android/app/src/main/res'
    bg = Image.new('RGBA', (432, 432))
    grad = Image.new('RGBA', (432, 432))
    px = grad.load()
    for y in range(432):
        for x in range(432):
            t = (x + y) / 863
            px[x, y] = (
                int(PURPLE_TOP[0] + (PURPLE_BOT[0] - PURPLE_TOP[0]) * t),
                int(PURPLE_TOP[1] + (PURPLE_BOT[1] - PURPLE_TOP[1]) * t),
                int(PURPLE_TOP[2] + (PURPLE_BOT[2] - PURPLE_TOP[2]) * t),
                255,
            )
    bg.paste(grad, (0, 0))
    bg.save(f'{res}/mipmap-anydpi-v26/ic_launcher_background.png')
    # Foreground: monogram only, scaled into the 66% safe zone.
    mono = Image.new('RGBA', (1024, 1024), (0, 0, 0, 0))
    import PIL.ImageDraw as _D
    d = _D.Draw(mono)
    font = ImageFont.truetype(FONT, int(1024 * 0.52))
    bbox = d.textbbox((0, 0), 'F', font=font)
    w, h = bbox[2] - bbox[0], bbox[3] - bbox[1]
    x = (1024 - w) / 2 - bbox[0]
    y = (1024 - h) / 2 - bbox[1]
    d.text((x, y), 'F', font=font, fill=WHITE)
    dot_r = 1024 * 0.055
    dot_cx = x + bbox[0] + w + dot_r * 0.7
    dot_cy = y + bbox[1] + h - dot_r * 0.6
    d.ellipse([dot_cx - dot_r, dot_cy - dot_r, dot_cx + dot_r, dot_cy + dot_r],
              fill=GREEN)
    safe = mono.resize((285, 285), Image.LANCZOS)  # 66% of 432
    canvas = Image.new('RGBA', (432, 432), (0, 0, 0, 0))
    canvas.paste(safe, ((432 - 285) // 2, (432 - 285) // 2), safe)
    canvas.save(f'{res}/mipmap-anydpi-v26/ic_launcher_foreground.png')

def main() -> None:
    master = base_tile(MASTER)
    draw_monogram(master)
    try:
        write_adaptive_android(master)
    except FileNotFoundError:
        pass  # res/mipmap-anydpi-v26 dir absent

    # Android mipmaps.
    android_sizes = {
        'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192,
    }
    for dpi, px in android_sizes.items():
        out = f'{REPO}/android/app/src/main/res/mipmap-{dpi}/ic_launcher.png'
        master.resize((px, px), Image.LANCZOS).save(out)
        print('wrote', out)

    # Linux freedesktop icons.
    linux_dir = f'{REPO}/packaging/linux/icons'
    os.makedirs(linux_dir, exist_ok=True)
    for px in (512, 256, 128, 64, 48, 32):
        out = f'{linux_dir}/filmify_{px}.png'
        master.resize((px, px), Image.LANCZOS).save(out)
        print('wrote', out)

    # Windows .ico (multi-resolution).
    ico_path = f'{REPO}/windows/runner/resources/app_icon.ico'
    if os.path.isdir(f'{REPO}/windows'):
        master.resize((256, 256), Image.LANCZOS).save(
            ico_path, sizes=[(256, 256), (128, 128), (64, 64), (48, 48),
                             (32, 32), (16, 16)])
        print('wrote', ico_path)


if __name__ == '__main__':
    main()
