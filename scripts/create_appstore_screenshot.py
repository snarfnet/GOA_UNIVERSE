#!/usr/bin/env python3
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[1]
BACKGROUND = ROOT / "Assets.xcassets" / "GoaPsyBackground.imageset" / "goa-psy-background.png"
OUTPUT = ROOT / "AppStore" / "Screenshots" / "iphone65-1.png"
SIZE = (1242, 2688)


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    candidates = [
        r"C:\Windows\Fonts\arialbd.ttf" if bold else r"C:\Windows\Fonts\arial.ttf",
        r"C:\Windows\Fonts\segoeuib.ttf" if bold else r"C:\Windows\Fonts\segoeui.ttf",
    ]
    for candidate in candidates:
        path = Path(candidate)
        if path.exists():
            return ImageFont.truetype(str(path), size)
    return ImageFont.load_default()


def text_center(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], value: str, fnt, fill) -> None:
    bbox = draw.textbbox((0, 0), value, font=fnt)
    x = box[0] + (box[2] - box[0] - (bbox[2] - bbox[0])) / 2
    y = box[1] + (box[3] - box[1] - (bbox[3] - bbox[1])) / 2
    draw.text((x, y), value, font=fnt, fill=fill)


def rounded_panel(draw: ImageDraw.ImageDraw, box, outline, fill=(5, 9, 22, 188), radius=30, width=3) -> None:
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


def main() -> None:
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)

    bg = Image.open(BACKGROUND).convert("RGB")
    bg_ratio = bg.width / bg.height
    target_ratio = SIZE[0] / SIZE[1]
    if bg_ratio > target_ratio:
        new_h = SIZE[1]
        new_w = int(new_h * bg_ratio)
    else:
        new_w = SIZE[0]
        new_h = int(new_w / bg_ratio)
    bg = bg.resize((new_w, new_h), Image.Resampling.LANCZOS)
    left = (new_w - SIZE[0]) // 2
    top = (new_h - SIZE[1]) // 2
    image = bg.crop((left, top, left + SIZE[0], top + SIZE[1])).convert("RGBA")

    overlay = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay)
    od.rectangle((0, 0, SIZE[0], SIZE[1]), fill=(0, 0, 0, 82))
    od.rectangle((0, 1180, SIZE[0], SIZE[1]), fill=(0, 0, 0, 120))
    image = Image.alpha_composite(image, overlay)

    glow = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    for box, color in [
        ((-180, 210, 760, 1150), (0, 255, 230, 88)),
        ((500, 760, 1500, 1790), (255, 40, 190, 76)),
        ((170, 1500, 1120, 2460), (255, 210, 40, 58)),
    ]:
        gd.ellipse(box, fill=color)
    glow = glow.filter(ImageFilter.GaussianBlur(72))
    image = Image.alpha_composite(image, glow)

    draw = ImageDraw.Draw(image)
    cyan = (80, 255, 232, 255)
    gold = (255, 205, 74, 255)
    magenta = (255, 70, 190, 255)
    white = (246, 248, 255, 255)
    muted = (185, 196, 220, 255)

    draw.text((92, 132), "GOA", font=font(118, True), fill=cyan)
    draw.text((92, 256), "UNIVERSE", font=font(118, True), fill=gold)
    draw.text((96, 400), "GENERATOR", font=font(34, True), fill=magenta)

    draw.text((96, 505), "Analyze a track.", font=font(58, True), fill=white)
    draw.text((96, 575), "Generate a Goa trance pattern.", font=font(48, True), fill=white)

    chip_y = 705
    chips = [("144 BPM", gold), ("MELANCHOLIC", magenta), ("ARMED", cyan)]
    x = 92
    for label, color in chips:
        text_box = draw.textbbox((0, 0), label, font=font(27, True))
        w = text_box[2] - text_box[0] + 58
        draw.rounded_rectangle((x, chip_y, x + w, chip_y + 70), radius=18, fill=(0, 0, 0, 150), outline=color, width=3)
        text_center(draw, (x, chip_y, x + w, chip_y + 70), label, font(27, True), color)
        x += w + 20

    rounded_panel(draw, (74, 880, 1168, 1196), cyan)
    draw.text((122, 930), "SOURCE SIGNAL", font=font(29, True), fill=cyan)
    draw.text((122, 1012), "psychedelic_loop.wav", font=font(37, True), fill=white)
    draw.text((122, 1070), "MP3 / WAV / AIFF", font=font(25, True), fill=muted)
    draw.rounded_rectangle((780, 1000, 1112, 1104), radius=22, fill=(80, 255, 232, 230))
    text_center(draw, (780, 1000, 1112, 1104), "SELECT", font(30, True), (0, 0, 0, 255))

    rounded_panel(draw, (74, 1260, 1168, 1788), gold)
    draw.text((122, 1312), "DETECTED PARAMETERS", font=font(29, True), fill=gold)
    tiles = [("BPM", "144", gold), ("KEY", "A min", cyan), ("TIME", "187s", magenta)]
    tx = 122
    for label, value, color in tiles:
        draw.rounded_rectangle((tx, 1405, tx + 302, 1594), radius=24, fill=(255, 255, 255, 20), outline=color, width=3)
        text_center(draw, (tx, 1432, tx + 302, 1486), label, font(26, True), muted)
        text_center(draw, (tx, 1490, tx + 302, 1582), value, font(48, True), color)
        tx += 344

    bars = [("LOW", 0.74, magenta), ("MID", 0.56, cyan), ("HIGH", 0.68, gold)]
    bx = 134
    for label, amount, color in bars:
        draw.text((bx, 1642), label, font=font(23, True), fill=muted)
        draw.rounded_rectangle((bx, 1690, bx + 280, 1726), radius=18, fill=(255, 255, 255, 32))
        draw.rounded_rectangle((bx, 1690, bx + int(280 * amount), 1726), radius=18, fill=color)
        bx += 330

    rounded_panel(draw, (74, 1850, 1168, 2450), magenta)
    draw.text((122, 1902), "LIVE SEQUENCER", font=font(29, True), fill=magenta)
    step_x = 122
    for index in range(16):
        color = gold if index == 5 else (80, 255, 232, 180 if index % 4 == 0 else 92)
        height = 94 if index % 4 == 0 else 66
        draw.rounded_rectangle((step_x, 2016 + (94 - height), step_x + 48, 2110), radius=9, fill=color)
        step_x += 61

    draw.rounded_rectangle((122, 2220, 442, 2340), radius=28, fill=(80, 255, 232, 235))
    text_center(draw, (122, 2220, 442, 2340), "PLAY", font(38, True), (0, 0, 0, 255))
    draw.rounded_rectangle((490, 2220, 770, 2340), radius=28, fill=(0, 0, 0, 145), outline=cyan, width=3)
    text_center(draw, (490, 2220, 770, 2340), "STEP 6", font(32, True), cyan)

    draw.text((91, 2530), "On-device audio analysis. Built for instant psychedelic sketching.", font=font(30, True), fill=white)
    image.convert("RGB").save(OUTPUT, "PNG", optimize=True)
    print(OUTPUT)


if __name__ == "__main__":
    main()
