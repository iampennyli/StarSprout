#!/usr/bin/env python3
"""
生成 App 图标（1024×1024，不透明 PNG）：星空里的漂浮小岛 + 带笑脸的小树，和 App 内画风一致。
用法：python3 scripts/icon/generate_icon.py
输出：StarSprout/Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png
"""
import os, random
from PIL import Image, ImageDraw, ImageFilter

S = 4                      # 超采样倍数，最后缩小抗锯齿
W = 1024 * S
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "StarSprout", "Resources", "Assets.xcassets", "AppIcon.appiconset", "icon-1024.png")


def hexc(h, a=255):
    return ((h >> 16) & 255, (h >> 8) & 255, h & 255, a)


def lerp(c1, c2, t):
    return tuple(int(c1[i] + (c2[i] - c1[i]) * t) for i in range(4))


def radial_bg():
    img = Image.new("RGBA", (W, W))
    px = img.load()
    inner, outer = hexc(0x3A3F9C), hexc(0x12142F)
    cx, cy = W * 0.5, W * 0.38
    maxd = (W * 0.85)
    small = Image.new("RGBA", (256, 256))
    sp = small.load()
    for y in range(256):
        for x in range(256):
            d = (((x * W / 256 - cx) ** 2 + (y * W / 256 - cy) ** 2) ** 0.5) / maxd
            sp[x, y] = lerp(inner, outer, min(1, d))
    return small.resize((W, W), Image.BICUBIC)


def ellipse(d, cx, cy, rx, ry, fill):
    d.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=fill)


def soft(img, shapes, blur=0):
    """半透明形状要叠加到图上（直接画会把底色的透明度一起覆盖掉）"""
    layer = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    ld = ImageDraw.Draw(layer)
    for (cx, cy, rx, ry, fill) in shapes:
        ld.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=fill)
    if blur:
        layer = layer.filter(ImageFilter.GaussianBlur(blur))
    return Image.alpha_composite(img, layer)


def vgrad_mask_fill(base, shape_mask, top, bottom, y0, y1):
    """在 shape_mask 区域内填竖直渐变"""
    grad = Image.new("RGBA", (W, W))
    gd = ImageDraw.Draw(grad)
    for y in range(int(y0), int(y1) + 1, S):
        t = (y - y0) / max(1, (y1 - y0))
        gd.rectangle([0, y, W, y + S], fill=lerp(top, bottom, max(0, min(1, t))))
    base.paste(grad, (0, 0), shape_mask)


def main():
    random.seed(3)
    img = radial_bg()
    d = ImageDraw.Draw(img)

    # 星星
    for _ in range(70):
        x, y = random.uniform(0, W), random.uniform(0, W * 0.75)
        r = random.choice([1.2, 1.6, 2.2, 3.0]) * S * 2
        ellipse(d, x, y, r, r, lerp(hexc(0x2A2F7A), hexc(0xFFFFFF), random.uniform(0.5, 0.95)))
    # 几颗十字星
    for (x, y, r) in [(0.18, 0.2, 18), (0.83, 0.15, 14), (0.76, 0.42, 10)]:
        x, y, r = x * W, y * W, r * S
        d.polygon([(x, y - r * 2), (x + r * 0.35, y - r * 0.35), (x + r * 2, y), (x + r * 0.35, y + r * 0.35),
                   (x, y + r * 2), (x - r * 0.35, y + r * 0.35), (x - r * 2, y), (x - r * 0.35, y - r * 0.35)],
                  fill=hexc(0xFFF1A8))

    cx, cy = W * 0.5, W * 0.63          # 小岛顶面中心
    a, b, t = W * 0.36, W * 0.12, W * 0.06

    # 小岛底下光晕
    glow = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse([cx - a * 1.1, cy - b, cx + a * 1.1, cy + b * 3.2], fill=hexc(0x52C27A, 90))
    img = Image.alpha_composite(img, glow.filter(ImageFilter.GaussianBlur(40 * S)))
    d = ImageDraw.Draw(img)

    # 底锥（岩石）
    cone = Image.new("L", (W, W), 0)
    cd = ImageDraw.Draw(cone)
    y0 = cy + t
    pts = [(cx - a, y0)]
    import math
    for i in range(41):
        ang = math.pi - math.pi * i / 40
        pts.append((cx + a * math.cos(ang), y0 + b * math.sin(ang)))
    pts += [(cx + a * 0.55, y0 + b + W * 0.07), (cx + a * 0.2, y0 + b + W * 0.15), (cx + W * 0.02, y0 + b + W * 0.2),
            (cx - a * 0.25, y0 + b + W * 0.12), (cx - a * 0.62, y0 + b + W * 0.05)]
    cd.polygon(pts, fill=255)
    vgrad_mask_fill(img, cone, hexc(0x9A6A46), hexc(0x4E4286), y0, y0 + b + W * 0.2)

    # 侧面（泥土）
    side = Image.new("L", (W, W), 0)
    sd = ImageDraw.Draw(side)
    sp = [(cx - a, cy)]
    for i in range(41):
        ang = math.pi - math.pi * i / 40
        sp.append((cx + a * math.cos(ang), cy + t + b * math.sin(ang)))
    for i in range(41):
        ang = math.pi * i / 40
        sp.append((cx + a * math.cos(ang), cy + b * math.sin(ang)))
    sd.polygon(sp, fill=255)
    vgrad_mask_fill(img, side, hexc(0xB07A4F), hexc(0x8A5C3C), cy, cy + t + b)
    d = ImageDraw.Draw(img)

    # 草地边缘 + 顶面 + 高光
    ellipse(d, cx, cy + 8 * S, a, b, hexc(0x3A9E5E))
    top = Image.new("L", (W, W), 0)
    ImageDraw.Draw(top).ellipse([cx - a, cy - b, cx + a, cy + b], fill=255)
    vgrad_mask_fill(img, top, hexc(0x9BEBA6), hexc(0x52C27A), cy - b, cy + b)
    img = soft(img, [(cx - a * 0.25, cy - b * 0.4, a * 0.5, b * 0.32, hexc(0xFFFFFF, 40))], blur=4 * S)
    d = ImageDraw.Draw(img)

    # 树影
    shadow = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).ellipse([cx - a * 0.42, cy - b * 0.25, cx + a * 0.42, cy + b * 0.3], fill=(20, 48, 31, 90))
    img = Image.alpha_composite(img, shadow.filter(ImageFilter.GaussianBlur(6 * S)))
    d = ImageDraw.Draw(img)

    # 树干
    tw, th = W * 0.065, W * 0.2
    trunk_top = cy - th
    d.polygon([(cx - tw * 0.9, cy + 4 * S), (cx - tw * 0.38, cy - th * 0.3), (cx - tw * 0.3, trunk_top),
               (cx + tw * 0.3, trunk_top), (cx + tw * 0.38, cy - th * 0.3), (cx + tw * 0.9, cy + 4 * S)], fill=hexc(0xB97C4C))
    d.polygon([(cx + tw * 0.05, trunk_top), (cx + tw * 0.3, trunk_top), (cx + tw * 0.38, cy - th * 0.3),
               (cx + tw * 0.9, cy + 4 * S), (cx + tw * 0.2, cy + 4 * S)], fill=hexc(0x93592F))

    # 树冠：云朵状
    ccx, ccy, cw = cx, trunk_top - W * 0.12, W * 0.5
    blobs = [(0.50, 0.36, 0.28), (0.31, 0.30, 0.19), (0.69, 0.31, 0.19), (0.25, 0.56, 0.23),
             (0.75, 0.56, 0.23), (0.50, 0.62, 0.27), (0.13, 0.70, 0.13), (0.87, 0.70, 0.13)]
    ch = cw * 0.83
    ox, oy = ccx - cw / 2, ccy - ch / 2

    def draw_blobs(color, dy=0, blist=blobs):
        for (bx, by, br) in blist:
            r = br * cw
            ellipse(d, ox + bx * cw, oy + by * ch + dy, r, r, color)

    draw_blobs(hexc(0x37A867), dy=ch * 0.05)
    canopy = Image.new("L", (W, W), 0)
    cdr = ImageDraw.Draw(canopy)
    for (bx, by, br) in blobs:
        r = br * cw
        cdr.ellipse([ox + bx * cw - r, oy + by * ch - r, ox + bx * cw + r, oy + by * ch + r], fill=255)
    vgrad_mask_fill(img, canopy, hexc(0xA6F5B4), hexc(0x5ED488), oy, oy + ch)
    img = soft(img, [(ox + bx * cw, oy + by * ch, br * cw, br * cw, hexc(0xFFFFFF, 100))
                     for (bx, by, br) in [(0.33, 0.24, 0.075), (0.45, 0.17, 0.04), (0.20, 0.47, 0.035)]])
    d = ImageDraw.Draw(img)

    # 笑脸
    fy = oy + ch * 0.6
    ink = hexc(0x23264F)
    es = cw * 0.075
    for sx in (-1, 1):
        ex = ccx + sx * es * 1.3
        ellipse(d, ex, fy, es * 0.42, es * 0.55, ink)
        ellipse(d, ex + es * 0.12, fy - es * 0.2, es * 0.15, es * 0.15, hexc(0xFFFFFF))
        img = soft(img, [(ccx + sx * es * 2.6, fy + es * 0.55, es * 0.55, es * 0.25, hexc(0xFF7AC6, 140))])
        d = ImageDraw.Draw(img)
    # 嘴
    mw, mh = es * 0.8, es * 0.55
    d.chord([ccx - mw, fy + es * 0.35 - mh, ccx + mw, fy + es * 0.35 + mh], 0, 180, fill=hexc(0xE2557F), outline=ink, width=int(S * 4))

    # 树顶的星星
    sx0, sy0, r = ccx, oy + ch * 0.06, W * 0.055
    pts = []
    for i in range(10):
        ang = -math.pi / 2 + i * math.pi / 5
        rr = r if i % 2 == 0 else r * 0.45
        pts.append((sx0 + rr * math.cos(ang), sy0 + rr * math.sin(ang)))
    glow = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse([sx0 - r * 1.6, sy0 - r * 1.6, sx0 + r * 1.6, sy0 + r * 1.6], fill=hexc(0xFFC94D, 120))
    img = Image.alpha_composite(img, glow.filter(ImageFilter.GaussianBlur(20 * S)))
    d = ImageDraw.Draw(img)
    d.polygon(pts, fill=hexc(0xFFD45C), outline=hexc(0xE0A21E))

    # 星环（前半圈）
    ring = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    rd = ImageDraw.Draw(ring)
    rx, ry, rcy = a * 1.2, b * 1.25, cy + t * 0.8
    rd.arc([cx - rx, rcy - ry, cx + rx, rcy + ry], 0, 180, fill=hexc(0xFF7AC6, 230), width=int(10 * S))
    img = Image.alpha_composite(img, ring)

    out = img.resize((1024, 1024), Image.LANCZOS).convert("RGB")
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    out.save(OUT)
    print("生成", OUT)


if __name__ == "__main__":
    main()
