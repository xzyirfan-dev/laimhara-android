"""Pustaka gambar 2D kecil untuk menghasilkan ikon & bingkai UI Laimhara (PIL + numpy, supersample 4x)."""
import math
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageChops

S = 512  # kanvas kerja; hasil akhir di-downscale


def rgb(h):
    h = h.lstrip('#')
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def shade(c, f):
    """f>1 mencerahkan, f<1 menggelapkan."""
    if f >= 1:
        t = min(1.0, f - 1.0)
        return tuple(int(v + (255 - v) * t) for v in c[:3])
    return tuple(int(v * f) for v in c[:3])


def mix(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


# palet tier (sama dengan Gfx.palette di Godot)
PAL = [
    dict(main=rgb('8c613d'), dark=rgb('523821'), trim=rgb('bf9959'), glow=rgb('66d9ff'), cape=rgb('992620')),    # Latihan
    dict(main=rgb('b87538'), dark=rgb('663d1a'), trim=rgb('f2bf59'), glow=rgb('ff9933'), cape=rgb('8c1f1a')),    # Perunggu
    dict(main=rgb('6180bd'), dark=rgb('334775'), trim=rgb('ffe659'), glow=rgb('fff259'), cape=rgb('263380')),    # Badai
    dict(main=rgb('336b4d'), dark=rgb('1a3829'), trim=rgb('ccd9cc'), glow=rgb('66ff8c'), cape=rgb('1a4d33')),    # Penjaga
    dict(main=rgb('ebe0c2'), dark=rgb('9e8c61'), trim=rgb('ffd14d'), glow=rgb('ffd94d'), cape=rgb('bf2620')),    # Tanduk Putih
    dict(main=rgb('471f57'), dark=rgb('1f0d29'), trim=rgb('d940a0'), glow=rgb('ff40b3'), cape=rgb('800d33')),    # Moriath
    dict(main=rgb('d1e6fa'), dark=rgb('5980b3'), trim=rgb('8ce6ff'), glow=rgb('59e6ff'), cape=rgb('265aa6')),    # Ragnok
]
OUT = (14, 10, 12)


class Cv:
    def __init__(self, size=S):
        self.n = size
        self.img = Image.new('RGBA', (size, size), (0, 0, 0, 0))

    # ---- primitif ----
    def _grad(self, bbox, c1, c2, mode='v'):
        x0, y0, x1, y1 = [int(v) for v in bbox]
        w, h = max(1, x1 - x0), max(1, y1 - y0)
        if mode == 'v':
            t = np.linspace(0, 1, h)[:, None] * np.ones((1, w))
        elif mode == 'h':
            t = np.ones((h, 1)) * np.linspace(0, 1, w)[None, :]
        else:  # diagonal
            t = (np.linspace(0, 1, h)[:, None] + np.linspace(0, 1, w)[None, :]) / 2
        a = np.array(c1[:3], dtype=float)
        b = np.array(c2[:3], dtype=float)
        arr = a[None, None, :] + (b - a)[None, None, :] * t[:, :, None]
        im = Image.fromarray(arr.astype(np.uint8), 'RGB').convert('RGBA')
        return im, (x0, y0)

    def _paste_masked(self, shape_draw, c1, c2, mode, bbox, alpha=255):
        mask = Image.new('L', (self.n, self.n), 0)
        shape_draw(ImageDraw.Draw(mask), 255)
        g, (x0, y0) = self._grad(bbox, c1, c2, mode)
        layer = Image.new('RGBA', (self.n, self.n), (0, 0, 0, 0))
        layer.paste(g, (x0, y0))
        if alpha != 255:
            mask = mask.point(lambda v: v * alpha // 255)
        layer.putalpha(ImageChops.multiply(mask, layer.getchannel('A')) if False else mask)
        self.img.alpha_composite(layer)

    def poly(self, pts, c1, c2=None, outline=OUT, ow=7, mode='v', alpha=255):
        pts = [tuple(p) for p in pts]
        c2 = c2 or shade(c1, 0.6)
        xs = [p[0] for p in pts]
        ys = [p[1] for p in pts]
        bbox = (min(xs), min(ys), max(xs) + 1, max(ys) + 1)
        self._paste_masked(lambda d, f: d.polygon(pts, fill=f), c1, c2, mode, bbox, alpha)
        if outline:
            d = ImageDraw.Draw(self.img)
            d.line(pts + [pts[0]], fill=tuple(outline) + (255,), width=ow, joint='curve')
        return self

    def ellipse(self, box, c1, c2=None, outline=OUT, ow=7, mode='v', alpha=255):
        c2 = c2 or shade(c1, 0.6)
        self._paste_masked(lambda d, f: d.ellipse(box, fill=f), c1, c2, mode, box, alpha)
        if outline:
            ImageDraw.Draw(self.img).ellipse(box, outline=tuple(outline) + (255,), width=ow)
        return self

    def circle(self, cx, cy, r, c1, c2=None, **kw):
        return self.ellipse((cx - r, cy - r, cx + r, cy + r), c1, c2, **kw)

    def rrect(self, box, rad, c1, c2=None, outline=OUT, ow=7, mode='v', alpha=255):
        if c1 is not None:
            c2 = c2 or shade(c1, 0.6)
            self._paste_masked(lambda d, f: d.rounded_rectangle(box, rad, fill=f), c1, c2, mode, box, alpha)
        if outline:
            ImageDraw.Draw(self.img).rounded_rectangle(box, rad, outline=tuple(outline) + (255,), width=ow)
        return self

    def line(self, pts, col, w=8, alpha=255):
        d = ImageDraw.Draw(self.img)
        d.line([tuple(p) for p in pts], fill=tuple(col[:3]) + (alpha,), width=int(w), joint='curve')
        return self

    def arc(self, box, a0, a1, col, w=8):
        ImageDraw.Draw(self.img).arc(box, a0, a1, fill=tuple(col[:3]) + (255,), width=int(w))
        return self

    def shine(self, pts, alpha=70):
        """sorotan putih lembut di atas bentuk"""
        lay = Image.new('RGBA', (self.n, self.n), (0, 0, 0, 0))
        ImageDraw.Draw(lay).polygon([tuple(p) for p in pts], fill=(255, 255, 255, alpha))
        self.img.alpha_composite(lay)
        return self

    def glow(self, cx, cy, r, col, strength=0.9, blur=None):
        lay = Image.new('RGBA', (self.n, self.n), (0, 0, 0, 0))
        d = ImageDraw.Draw(lay)
        d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=tuple(col[:3]) + (int(255 * strength),))
        lay = lay.filter(ImageFilter.GaussianBlur(blur or r * 0.6))
        self.img.alpha_composite(lay)
        return self

    def glow_poly(self, pts, col, strength=0.8, blur=14):
        lay = Image.new('RGBA', (self.n, self.n), (0, 0, 0, 0))
        ImageDraw.Draw(lay).polygon([tuple(p) for p in pts], fill=tuple(col[:3]) + (int(255 * strength),))
        lay = lay.filter(ImageFilter.GaussianBlur(blur))
        self.img.alpha_composite(lay)
        return self

    def gem(self, cx, cy, r, col, facets=6):
        """permata bersegi dengan sorotan"""
        self.glow(cx, cy, r * 1.7, col, 0.55)
        pts = [(cx + math.cos(a) * r, cy + math.sin(a) * r) for a in [math.tau * i / facets - math.pi / 2 for i in range(facets)]]
        self.poly(pts, shade(col, 1.45), shade(col, 0.55), ow=max(4, int(r * 0.16)))
        inner = [(cx + (x - cx) * 0.55, cy + (y - cy) * 0.55) for x, y in pts]
        self.poly(inner, shade(col, 1.2), shade(col, 0.8), outline=None)
        self.shine([(cx - r * 0.5, cy - r * 0.6), (cx + r * 0.1, cy - r * 0.8), (cx - r * 0.1, cy - r * 0.1), (cx - r * 0.55, cy - r * 0.05)], 120)
        return self

    def shadow(self, strength=110, dy=14, blur=12):
        a = self.img.getchannel('A')
        sh = Image.new('RGBA', (self.n, self.n), (0, 0, 0, 0))
        black = Image.new('RGBA', (self.n, self.n), (0, 0, 0, strength))
        sh.paste(black, (0, dy), a)
        sh = sh.filter(ImageFilter.GaussianBlur(blur))
        base = Image.new('RGBA', (self.n, self.n), (0, 0, 0, 0))
        base.alpha_composite(sh)
        base.alpha_composite(self.img)
        self.img = base
        return self

    def rotate(self, deg):
        self.img = self.img.rotate(deg, resample=Image.BICUBIC, center=(self.n / 2, self.n / 2))
        return self

    def save(self, path, size=128, fit=False, fill=0.94):
        img = self.img
        if fit:
            bb = img.getchannel('A').point(lambda v: 255 if v > 24 else 0).getbbox()
            if bb:
                img = img.crop(bb)
                k = fill * self.n / max(img.size)
                img = img.resize((max(1, int(img.size[0] * k)), max(1, int(img.size[1] * k))), Image.LANCZOS)
                canvas = Image.new('RGBA', (self.n, self.n), (0, 0, 0, 0))
                canvas.alpha_composite(img, ((self.n - img.size[0]) // 2, (self.n - img.size[1]) // 2))
                img = canvas
        im = img.resize((size, size), Image.LANCZOS)
        im.save(path)
        return im


def pts_scale(pts, cx, cy, k):
    return [(cx + (x - cx) * k, cy + (y - cy) * k) for x, y in pts]


def mirror_x(pts, cx=S / 2):
    return [(2 * cx - x, y) for x, y in pts]
