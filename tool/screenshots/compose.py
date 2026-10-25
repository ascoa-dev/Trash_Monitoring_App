"""Frames raw emulator captures into store-ready marketing screenshots.

../../store_listings/raw/<device>/<lang>/<name>.png  ->  ../../store_listings/<store>/<lang>/screenshots/<slot>/<nn>_<name>.png

Run:  python compose.py
"""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = Path(__file__).parent
OUT = HERE.parent.parent / "store_listings"
FONT_BOLD = "C:/Windows/Fonts/segoeuib.ttf"
FONT_REG = "C:/Windows/Fonts/segoeui.ttf"

# Brand colours (app_colors.dart / web)
TOP, BOTTOM = (24, 51, 61), (53, 113, 135)  # #18333D -> #357187
GREEN = (65, 147, 16)  # #419310
BEZEL = (12, 22, 27)

# Store order: (raw name, EN caption, FR caption)
SHOTS = [
    ("01_home", "Track cleanups in your community", "Suivez les nettoyages de votre communauté"),
    ("02_cleanup_items", "Log every item you collect", "Enregistrez chaque déchet collecté"),
    ("03_stats", "See your impact in numbers", "Visualisez votre impact en chiffres"),
    ("04_map", "Map cleanups across Cameroon", "Cartographiez les nettoyages au Cameroun"),
    ("09_community", "Report plastic hotspots", "Signalez les points noirs de plastique"),
    ("05_achievements", "Earn badges as you make a difference", "Gagnez des badges en agissant"),
    ("06_streak", "Keep your weekly streak going", "Gardez votre série hebdomadaire"),
    ("10_detail", "Every cleanup, in detail", "Chaque nettoyage en détail"),
]

# (store, slot folder, raw device, canvas size)
TARGETS = [
    ("playstore", "phone", "phone", (1080, 1920)),
    ("playstore", "tablet_7", "tablet_7", (1200, 2133)),
    ("playstore", "tablet_10", "tablet_10", (1440, 2560)),
    ("appstore", "iphone_6.3", "phone", (1206, 2622)),
    ("appstore", "ipad_13", "tablet_10", (2064, 2752)),
]


def gradient(size):
    w, h = size
    col = Image.new("RGB", (1, h))
    for y in range(h):
        t = y / (h - 1)
        col.putpixel((0, y), tuple(round(a + (b - a) * t) for a, b in zip(TOP, BOTTOM)))
    return col.resize(size)


def wrap(draw, text, font, max_w):
    lines, line = [], ""
    for word in text.split():
        trial = f"{line} {word}".strip()
        if draw.textlength(trial, font=font) <= max_w or not line:
            line = trial
        else:
            lines.append(line)
            line = word
    return lines + [line]


def framed(shot, width):
    """Screenshot inside a rounded dark bezel, with a soft shadow. Returns RGBA."""
    bezel = round(width * 0.03)
    inner_w = width - 2 * bezel
    screen = shot.resize((inner_w, round(shot.height * inner_w / shot.width)), Image.LANCZOS)
    h = screen.height + 2 * bezel
    r_out, r_in = round(width * 0.11), round(width * 0.085)
    pad = round(width * 0.08)  # room for the shadow
    out = Image.new("RGBA", (width + 2 * pad, h + 2 * pad), (0, 0, 0, 0))

    shadow = Image.new("L", out.size, 0)
    ImageDraw.Draw(shadow).rounded_rectangle((pad, pad + pad // 3, pad + width, pad + h + pad // 3), r_out, fill=110)
    out.putalpha(shadow.filter(ImageFilter.GaussianBlur(pad // 2)))
    body = Image.new("RGBA", out.size, (0, 0, 0, 0))
    ImageDraw.Draw(body).rounded_rectangle((pad, pad, pad + width, pad + h), r_out, fill=BEZEL + (255,))
    out = Image.alpha_composite(out, body)

    mask = Image.new("L", screen.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, *screen.size), r_in, fill=255)
    out.paste(screen, (pad + bezel, pad + bezel), mask)
    return out, pad


def ios_top(shot):
    """Swap the Android status bar for an iPhone one with a Dynamic Island.

    The top ANDROID_BAR px are replaced by a taller IOS_BAR band (the first
    content row stretched upward), so the island never covers app content.
    Proportions follow a 393pt-wide iPhone, scaled to the capture width.
    """
    w = shot.width
    pt = w / 393
    android_bar, ios_bar = round(w * 0.097), round(59 * pt)
    body = shot.crop((0, android_bar, w, shot.height))
    # Median-filter the first content row so stray text pixels don't streak.
    row = body.crop((0, 0, w, 1)).resize((w, 61)).filter(ImageFilter.MedianFilter(61))
    band = row.crop((0, 30, w, 31)).resize((w, ios_bar))
    out = Image.new("RGB", (w, ios_bar + body.height))
    out.paste(band, (0, 0))
    out.paste(body, (0, ios_bar))

    d = ImageDraw.Draw(out)
    r, g, b = band.resize((1, 1), Image.BOX).getpixel((0, 0))
    ink = (0, 0, 0) if 0.299 * r + 0.587 * g + 0.114 * b > 140 else (255, 255, 255)
    cy = 31 * pt  # status bar text centre line

    # Dynamic Island
    iw, ih, itop = 126 * pt, 37 * pt, 11 * pt
    d.rounded_rectangle(((w - iw) / 2, itop, (w + iw) / 2, itop + ih), ih / 2, fill=(0, 0, 0))

    # Clock
    d.text((52 * pt, cy), "9:41", font=ImageFont.truetype(FONT_BOLD, round(17 * pt)), fill=ink, anchor="mm")

    # Signal bars, Wi-Fi, battery (right side)
    x = w - 112 * pt
    for i in range(4):
        bh = (4 + i * 2.6) * pt
        d.rounded_rectangle((x + i * 4.6 * pt, cy + 5.5 * pt - bh, x + i * 4.6 * pt + 3 * pt, cy + 5.5 * pt), pt, fill=ink)
    wx, wy = w - 74 * pt, cy + 5 * pt
    for rad in (12.5, 8.3, 4.2):
        d.pieslice((wx - rad * pt, wy - rad * pt, wx + rad * pt, wy + rad * pt), 225, 315, fill=ink)
        inner = (rad - 2.4) * pt
        if rad > 4.2:
            d.pieslice((wx - inner, wy - inner, wx + inner, wy + inner), 225, 315, fill=band.getpixel((round(wx), 0)))
    bx, by, bw, bhh = w - 55 * pt, cy - 6 * pt, 25 * pt, 12 * pt
    d.rounded_rectangle((bx, by, bx + bw, by + bhh), 3.5 * pt, outline=ink, width=max(1, round(pt)))
    d.rounded_rectangle((bx + 2 * pt, by + 2 * pt, bx + bw - 2 * pt, by + bhh - 2 * pt), 2 * pt, fill=ink)
    d.rounded_rectangle((bx + bw + 1.2 * pt, cy - 2 * pt, bx + bw + 2.6 * pt, cy + 2 * pt), pt, fill=ink)
    return out


def compose(raw_path, caption, size, iphone=False):
    w, h = size
    canvas = gradient(size).convert("RGBA")
    draw = ImageDraw.Draw(canvas)

    # Caption: up to two lines, centred, with a short green accent bar above.
    font = ImageFont.truetype(FONT_BOLD, round(w * 0.068))
    lines = wrap(draw, caption, font, w * 0.86)
    if len(lines) > 2:
        font = ImageFont.truetype(FONT_BOLD, round(w * 0.056))
        lines = wrap(draw, caption, font, w * 0.88)
    line_h = font.size * 1.18
    y = h * 0.055
    bar_w, bar_h = w * 0.09, max(6, round(w * 0.008))
    draw.rounded_rectangle(((w - bar_w) / 2, y, (w + bar_w) / 2, y + bar_h), bar_h, fill=GREEN)
    y += bar_h + font.size * 0.55
    for line in lines:
        draw.text((w / 2, y), line, font=font, fill="white", anchor="ma")
        y += line_h
    # Always reserve two caption lines so devices line up across the set.
    top = y + line_h * (2 - len(lines)) + h * 0.035

    # Device: as wide as fits, may run off the bottom edge but keeps >= 80% of the screen visible.
    shot = Image.open(raw_path).convert("RGB")
    if iphone:
        shot = ios_top(shot)
    ratio = shot.height / shot.width
    dev_w = min(w * 0.80, (h - top) / (0.80 * ratio * 0.97))
    device, pad = framed(shot, round(dev_w))
    canvas.alpha_composite(device, (round((w - device.width) / 2), round(top - pad)))
    return canvas.convert("RGB")


def main():
    made = 0
    for store, slot, raw_dev, size in TARGETS:
        for lang in ("en", "fr"):
            for i, (name, en, fr) in enumerate(SHOTS, 1):
                raw = OUT / "raw" / raw_dev / lang / f"{name}.png"
                if not raw.exists():
                    continue
                dest = OUT / store / lang / "screenshots" / slot / f"{i:02d}_{name.split('_', 1)[1]}.png"
                dest.parent.mkdir(parents=True, exist_ok=True)
                compose(raw, en if lang == "en" else fr, size, iphone=slot.startswith("iphone")).save(dest, optimize=True)
                made += 1
    print(f"{made} screenshots -> {OUT}")


if __name__ == "__main__":
    main()
