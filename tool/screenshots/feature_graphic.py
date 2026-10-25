"""Play Store feature graphic (1024x500), EN + FR, from the raw phone captures.

Run:  python feature_graphic.py   ->  ../../store_listings/playstore/<lang>/feature_graphic.png
"""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

from compose import FONT_BOLD, FONT_REG, GREEN, framed

HERE = Path(__file__).parent
APP = HERE.parent.parent
W, H = 1024, 500
S = 2  # draw at 2x, downscale for crisp edges

TEXT = {
    "en": ("Log cleanups.", "Map plastic hotspots.", "Citizen science for a cleaner Cameroon"),
    "fr": ("Notez vos nettoyages.", "Cartographiez le plastique.", "Science participative pour un Cameroun propre"),
}


def background(w, h):
    # Diagonal brand gradient: deep teal top-left -> ocean teal bottom-right.
    a, b = (20, 44, 53), (46, 104, 124)
    small = Image.new("RGB", (64, 32))
    for x in range(64):
        for y in range(32):
            t = (x / 63) * 0.7 + (y / 31) * 0.3
            small.putpixel((x, y), tuple(round(p + (q - p) * t) for p, q in zip(a, b)))
    bg = small.resize((w, h), Image.BICUBIC).convert("RGBA")
    # Soft green glow behind the phones.
    glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse((w * 0.55, -h * 0.3, w * 1.25, h * 1.3), fill=GREEN + (55,))
    from PIL import ImageFilter
    return Image.alpha_composite(bg, glow.filter(ImageFilter.GaussianBlur(w // 12)))


def make(lang):
    w, h = W * S, H * S
    img = background(w, h)
    d = ImageDraw.Draw(img)
    line1, line2, sub = TEXT[lang]

    # Phones on the right, tilted and running off the bottom edge.
    for name, x, y, angle, width in [("04_map", 0.885, 0.22, -8, 0.185), ("01_home", 0.715, 0.13, 6, 0.20)]:
        shot = Image.open(HERE / "raw" / "phone" / lang / f"{name}.png").convert("RGB")
        dev, _ = framed(shot, round(w * width))
        dev = dev.rotate(angle, resample=Image.BICUBIC, expand=True)
        img.alpha_composite(dev, (round(w * x - dev.width / 2), round(h * y)))

    # Left column: icon + name, headline, subline.
    left = round(w * 0.055)
    icon = Image.open(APP / "assets" / "ASCOA" / "Icon.png").convert("RGBA")
    icon.thumbnail((round(h * 0.15), round(h * 0.15)), Image.LANCZOS)
    tile = round(h * 0.19)
    y0 = round(h * 0.15)
    d.rounded_rectangle((left, y0, left + tile, y0 + tile), round(tile * 0.24), fill=(255, 255, 255, 255))
    img.alpha_composite(icon, (left + (tile - icon.width) // 2, y0 + (tile - icon.height) // 2))
    name_f = ImageFont.truetype(FONT_BOLD, round(h * 0.085))
    by_f = ImageFont.truetype(FONT_REG, round(h * 0.045))
    d.text((left + tile + h * 0.035, y0 + tile * 0.47), "We Monitor", font=name_f, fill="white", anchor="ls")
    d.text((left + tile + h * 0.037, y0 + tile * 0.95), "par ASCOA" if lang == "fr" else "by ASCOA", font=by_f, fill=(190, 222, 160), anchor="ls")

    max_w = w * 0.47
    size = round(h * 0.10)
    head_f = ImageFont.truetype(FONT_BOLD, size)
    while max(d.textlength(t, font=head_f) for t in (line1, line2)) > max_w:
        size -= 2
        head_f = ImageFont.truetype(FONT_BOLD, size)
    y = y0 + tile + h * 0.17
    d.text((left, y), line1, font=head_f, fill="white", anchor="ls")
    d.text((left, y + size * 1.15), line2, font=head_f, fill=(150, 214, 92), anchor="ls")
    bar_y = y + size * 1.15 + h * 0.07
    d.rounded_rectangle((left, bar_y, left + w * 0.06, bar_y + h * 0.012), h, fill=GREEN)
    sub_f = ImageFont.truetype(FONT_REG, round(h * 0.048))
    while d.textlength(sub, font=sub_f) > max_w:
        sub_f = ImageFont.truetype(FONT_REG, sub_f.size - 2)
    d.text((left, bar_y + h * 0.085), sub, font=sub_f, fill=(215, 232, 236), anchor="ls")

    out = APP / "store_listings" / "playstore" / lang / "feature_graphic.png"
    out.parent.mkdir(parents=True, exist_ok=True)
    img.convert("RGB").resize((W, H), Image.LANCZOS).save(out, optimize=True)
    print(out)


if __name__ == "__main__":
    for lang in TEXT:
        make(lang)
