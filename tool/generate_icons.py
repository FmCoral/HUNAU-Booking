"""生成带圆角的应用图标。

用法：
    python tool/generate_icons.py

输入：logo/book.png
输出：
    assets/branding/app_icon_1024.png
    assets/branding/app_icon_512.png
    android/app/src/main/res/mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/ic_launcher.png
"""

from pathlib import Path

from PIL import Image, ImageChops, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "logo" / "book.png"
RADIUS_RATIO = 0.22

DENSITIES = {
    "mdpi": 48,
    "hdpi": 72,
    "xhdpi": 96,
    "xxhdpi": 144,
    "xxxhdpi": 192,
}


def render(size: int) -> Image.Image:
    """居中裁剪为正方形，叠加圆角遮罩后缩放。"""
    image = Image.open(SOURCE).convert("RGBA")
    width, height = image.size
    side = min(width, height)
    left = (width - side) // 2
    top = (height - side) // 2
    image = image.crop((left, top, left + side, top + side))

    scale = 4
    canvas = size * scale
    image = image.resize((canvas, canvas), Image.LANCZOS)

    mask = Image.new("L", (canvas, canvas), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [0, 0, canvas - 1, canvas - 1],
        radius=int(canvas * RADIUS_RATIO),
        fill=255,
    )

    alpha = ImageChops.multiply(image.getchannel("A"), mask)
    image.putalpha(alpha)
    return image.resize((size, size), Image.LANCZOS)


def main() -> None:
    if not SOURCE.exists():
        raise SystemExit(f"找不到源图：{SOURCE}")

    branding = ROOT / "assets" / "branding"
    branding.mkdir(parents=True, exist_ok=True)
    render(1024).save(branding / "app_icon_1024.png")
    render(512).save(branding / "app_icon_512.png")

    res = ROOT / "android" / "app" / "src" / "main" / "res"
    for density, size in DENSITIES.items():
        target = res / f"mipmap-{density}"
        target.mkdir(parents=True, exist_ok=True)
        render(size).save(target / "ic_launcher.png")

    print("图标生成完成")


if __name__ == "__main__":
    main()
