"""Bingkai UI (9-patch), tombol, bar, pad bulat. Gaya: panel gelap sci-fi dengan trim emas redup (Laghaim x BDO mobile)."""
import math
from lib import *

K = 4
GOLD = rgb('c9a45a')
GOLD_D = rgb('6b5530')
GOLD_L = rgb('f2d68a')
NAVY = rgb('141a28')
NAVY_L = rgb('222c44')
STEEL = rgb('8c9bb8')


def make(w, h, fn, final=None):
    n = max(w, h) * K
    cv = Cv(n)
    fn(cv, w * K, h * K)
    img = cv.img.crop((0, 0, w * K, h * K)).resize((w, h), Image.LANCZOS)
    return img


def rr(cv, x0, y0, x1, y1, rad, c1, c2, ow=0, oc=None, alpha=255):
    cv.rrect((x0, y0, x1, y1), rad, c1, c2, outline=oc if ow else None, ow=ow, alpha=alpha)


def panel(w=128, h=128, rad=14, top=NAVY_L, bot=rgb('0b0f18'), edge=GOLD_D, alpha=240, ornament=True):
    def f(cv, W, H):
        r = rad * K
        rr(cv, 0, 0, W - 1, H - 1, r, shade(edge, 0.3), shade(edge, 0.2))                          # tepi luar gelap
        rr(cv, 2 * K, 2 * K, W - 2 * K, H - 2 * K, r - 2 * K, edge, shade(edge, 0.6))               # garis emas
        rr(cv, 3.2 * K, 3.2 * K, W - 3.2 * K, H - 3.2 * K, r - 3 * K, top, bot, alpha=alpha)        # isi
        rr(cv, 5 * K, 5 * K, W - 5 * K, H - 5 * K, r - 5 * K, None, None, ow=K // 2, oc=shade(STEEL, 0.45))  # garis dalam tipis
        # kilau atas
        ImageDraw.Draw(cv.img).rounded_rectangle((6 * K, 6 * K, W - 6 * K, 6 * K + 5 * K), 3 * K, fill=(255, 255, 255, 18))
        if ornament:
            for sx, sy in [(0, 0), (1, 0), (0, 1), (1, 1)]:
                cx = 4 * K + sx * (W - 8 * K)
                cy = 4 * K + sy * (H - 8 * K)
                dx = 1 if sx == 0 else -1
                dy = 1 if sy == 0 else -1
                cv.poly([(cx, cy), (cx + dx * 14 * K, cy), (cx + dx * 10 * K, cy + dy * 3 * K), (cx + dx * 3 * K, cy + dy * 3 * K), (cx + dx * 3 * K, cy + dy * 10 * K), (cx, cy + dy * 14 * K)], GOLD_L, GOLD_D, outline=None)
                cv.circle(cx + dx * 5 * K, cy + dy * 5 * K, 2.2 * K, rgb('9ae8ff'), rgb('3a9ac0'), outline=None)
    return make(w, h, f)


def inset(w=64, h=64, rad=8):
    def f(cv, W, H):
        r = rad * K
        rr(cv, 0, 0, W - 1, H - 1, r, rgb('05070c'), rgb('05070c'))
        rr(cv, 1.5 * K, 1.5 * K, W - 1.5 * K, H - 1.5 * K, r - K, rgb('0e1320'), rgb('090c14'), ow=K, oc=rgb('2a3550'))
    return make(w, h, f)


def titlebar(w=256, h=56):
    def f(cv, W, H):
        r = 10 * K
        rr(cv, 0, 0, W - 1, H - 1, r, rgb('05070c'), rgb('05070c'))
        rr(cv, 1.5 * K, 1.5 * K, W - 1.5 * K, H - 1.5 * K, r - K, rgb('2d3c62'), rgb('151d33'), ow=K, oc=GOLD_D)
        ImageDraw.Draw(cv.img).rounded_rectangle((5 * K, 4 * K, W - 5 * K, 4 * K + 8 * K), 4 * K, fill=(255, 255, 255, 22))
        d = ImageDraw.Draw(cv.img)
        d.line([(10 * K, H - 5 * K), (W - 10 * K, H - 5 * K)], fill=GOLD + (255,), width=K)
        for x in (6 * K, W - 6 * K):
            cv.poly([(x, H / 2 - 7 * K), (x + 7 * K, H / 2), (x, H / 2 + 7 * K), (x - 7 * K, H / 2)], GOLD_L, GOLD_D, outline=None)
    return make(w, h, f)


def button(kind='normal', w=96, h=64):
    cols = {
        'normal': (rgb('34466e'), rgb('1b2644'), GOLD_D),
        'hover': (rgb('44598a'), rgb('24325a'), GOLD),
        'pressed': (rgb('14203c'), rgb('202e52'), GOLD),
        'disabled': (rgb('2c313c'), rgb('1c2028'), rgb('3c4250')),
        'gold': (rgb('e8bc5a'), rgb('9a6a1c'), rgb('4a3008')),
        'gold_p': (rgb('9a6a1c'), rgb('c89a3c'), rgb('4a3008')),
        'red': (rgb('c04a3a'), rgb('6a1a14'), rgb('3a0a08')),
        'green': (rgb('4aa860'), rgb('1a5a2c'), rgb('0a2a14')),
    }
    c1, c2, ed = cols[kind]

    def f(cv, W, H):
        r = 12 * K
        rr(cv, 0, 0, W - 1, H - 1, r, rgb('05070c'), rgb('05070c'))
        rr(cv, 1.5 * K, 1.5 * K, W - 1.5 * K, H - 1.5 * K, r - K, c1, c2, ow=int(1.6 * K), oc=ed)
        ImageDraw.Draw(cv.img).rounded_rectangle((5 * K, 4 * K, W - 5 * K, 4 * K + H * K / 5.5 / K * K * 0.5), 5 * K, fill=(255, 255, 255, 34 if kind != 'disabled' else 10))
        d = ImageDraw.Draw(cv.img)
        d.line([(8 * K, H - 4 * K), (W - 8 * K, H - 4 * K)], fill=(0, 0, 0, 90), width=K)
    return make(w, h, f)


def slot(rar_col=None, w=96, h=96, glow=True):
    base = rar_col or rgb('4a5878')

    def f(cv, W, H):
        r = 10 * K
        rr(cv, 0, 0, W - 1, H - 1, r, rgb('04060a'), rgb('04060a'))
        rr(cv, 1.5 * K, 1.5 * K, W - 1.5 * K, H - 1.5 * K, r - K, shade(base, 0.45), shade(base, 0.25), ow=int(2.2 * K), oc=base)
        rr(cv, 4.5 * K, 4.5 * K, W - 4.5 * K, H - 4.5 * K, r - 3 * K, rgb('1b2438'), rgb('0a0e18'))
        if rar_col is not None and glow:
            lay = Image.new('RGBA', (cv.n, cv.n), (0, 0, 0, 0))
            ImageDraw.Draw(lay).rounded_rectangle((5 * K, 5 * K, W - 5 * K, H - 5 * K), r - 3 * K, outline=base + (150,), width=int(3 * K))
            lay = lay.filter(ImageFilter.GaussianBlur(5 * K))
            cv.img.alpha_composite(lay)
        ImageDraw.Draw(cv.img).rounded_rectangle((7 * K, 6 * K, W - 7 * K, 6 * K + 6 * K), 3 * K, fill=(255, 255, 255, 18))
    return make(w, h, f)


def bar_frame(w=256, h=30):
    def f(cv, W, H):
        r = H / 2
        rr(cv, 0, 0, W - 1, H - 1, r, rgb('05070c'), rgb('05070c'))
        rr(cv, 1.2 * K, 1.2 * K, W - 1.2 * K, H - 1.2 * K, r - K, rgb('0a0d16'), rgb('141a28'), ow=int(1.8 * K), oc=rgb('8c9bb8'))
    return make(w, h, f)


def bar_fill(top, bot, w=256, h=30):
    def f(cv, W, H):
        r = H / 2
        rr(cv, 0, 0, W - 1, H - 1, r, top, bot)
        ImageDraw.Draw(cv.img).rounded_rectangle((H * 0.25, H * 0.12, W - H * 0.25, H * 0.12 + H * 0.28), H * 0.14, fill=(255, 255, 255, 80))
    return make(w, h, f)


def circle_pad(rim, inner_top, inner_bot, size=128, glow_col=None):
    def f(cv, W, H):
        cx, cy, R = W / 2, H / 2, W / 2 - 2 * K
        if glow_col is not None:
            cv.glow(cx, cy, R * 1.0, glow_col, 0.55, blur=R * 0.16)
        cv.circle(cx, cy, R, shade(rim, 0.35), shade(rim, 0.2), outline=None)
        cv.circle(cx, cy, R - 2 * K, shade(rim, 1.25), shade(rim, 0.55), outline=None)
        cv.circle(cx, cy, R - 7 * K, inner_top, inner_bot, outline=rgb('05070c'), ow=K)
        ImageDraw.Draw(cv.img).ellipse((cx - R * 0.62, cy - R * 0.88, cx + R * 0.62, cy - R * 0.18), fill=(255, 255, 255, 22))
        cv.arc((cx - R + 3 * K, cy - R + 3 * K, cx + R - 3 * K, cy + R - 3 * K), 200, 300, shade(rim, 1.6), int(1.6 * K))
    return make(size, size, f)


def ring(size=256, inner=0.82, col=GOLD, silver=True, ticks=False):
    def f(cv, W, H):
        cx, cy, R = W / 2, H / 2, W / 2 - 2 * K
        d = ImageDraw.Draw(cv.img)
        cv.circle(cx, cy, R, rgb('05070c'), rgb('05070c'), outline=None)
        cv.circle(cx, cy, R - K, shade(STEEL, 1.1) if silver else col, shade(STEEL, 0.4) if silver else shade(col, 0.5), outline=None)
        cv.circle(cx, cy, R * inner + 2 * K, rgb('05070c'), rgb('05070c'), outline=None)
        d.ellipse((cx - R * inner, cy - R * inner, cx + R * inner, cy + R * inner), fill=(0, 0, 0, 0))
        # lubangkan tengah
        m = Image.new('L', (cv.n, cv.n), 255)
        ImageDraw.Draw(m).ellipse((cx - R * inner, cy - R * inner, cx + R * inner, cy + R * inner), fill=0)
        a = ImageChops.multiply(cv.img.getchannel('A'), m)
        cv.img.putalpha(a)
        d = ImageDraw.Draw(cv.img)
        d.ellipse((cx - R * (inner + 0.02), cy - R * (inner + 0.02), cx + R * (inner + 0.02), cy + R * (inner + 0.02)), outline=GOLD + (255,), width=int(1.8 * K))
        if ticks:
            for a_ in range(0, 360, 90):
                x = cx + math.cos(math.radians(a_)) * R * 0.91
                y = cy + math.sin(math.radians(a_)) * R * 0.91
                cv.poly([(x - 4 * K, y), (x, y - 4 * K), (x + 4 * K, y), (x, y + 4 * K)], GOLD_L, GOLD_D, outline=None)
    return make(size, size, f)


def tab(on=False, w=96, h=56):
    def f(cv, W, H):
        r = 10 * K
        c1, c2 = (rgb('52689c'), rgb('2a3a66')) if on else (rgb('232d48'), rgb('141a2c'))
        rr(cv, 0, 0, W - 1, H + 8 * K, r, rgb('05070c'), rgb('05070c'))
        rr(cv, 1.5 * K, 1.5 * K, W - 1.5 * K, H + 8 * K, r - K, c1, c2, ow=int(1.6 * K), oc=GOLD if on else GOLD_D)
        if on:
            ImageDraw.Draw(cv.img).rounded_rectangle((5 * K, 4 * K, W - 5 * K, 4 * K + 10 * K), 4 * K, fill=(255, 255, 255, 40))
    return make(w, h, f)


def pill(w=64, h=30):
    def f(cv, W, H):
        r = H / 2
        rr(cv, 0, 0, W - 1, H - 1, r, rgb('05070c'), rgb('05070c'))
        rr(cv, 1.2 * K, 1.2 * K, W - 1.2 * K, H - 1.2 * K, r - K, rgb('1c2438'), rgb('0c1020'), ow=int(1.4 * K), oc=GOLD_D)
    return make(w, h, f)


def divider(w=256, h=6):
    def f(cv, W, H):
        arr = np.zeros((H, W, 4), dtype=np.uint8)
        t = np.linspace(0, 1, W)
        a = (np.sin(t * math.pi) ** 0.7 * 255).astype(np.uint8)
        arr[:, :, 0] = GOLD_L[0]
        arr[:, :, 1] = GOLD_L[1]
        arr[:, :, 2] = GOLD_L[2]
        arr[H // 2 - K:H // 2 + K, :, 3] = a[None, :]
        cv.img.paste(Image.fromarray(arr, 'RGBA'), (0, 0))
    return make(w, h, f)


def soft_circle(size=128, col=(255, 255, 255)):
    arr = np.zeros((size, size, 4), dtype=np.uint8)
    yy, xx = np.mgrid[0:size, 0:size]
    d = np.sqrt((xx - size / 2) ** 2 + (yy - size / 2) ** 2) / (size / 2)
    a = np.clip(1 - d, 0, 1) ** 1.6
    arr[:, :, 0], arr[:, :, 1], arr[:, :, 2] = col
    arr[:, :, 3] = (a * 255).astype(np.uint8)
    return Image.fromarray(arr, 'RGBA')


def joy(size=256, knob=False):
    def f(cv, W, H):
        cx, cy, R = W / 2, H / 2, W / 2 - 3 * K
        if knob:
            cv.circle(cx, cy, R, rgb('f2d68a'), rgb('6b5530'), outline=rgb('05070c'), ow=K)
            cv.circle(cx, cy, R * 0.72, rgb('2a3550'), rgb('0e1320'), outline=rgb('05070c'), ow=K)
            ImageDraw.Draw(cv.img).ellipse((cx - R * 0.5, cy - R * 0.62, cx + R * 0.5, cy - R * 0.1), fill=(255, 255, 255, 30))
        else:
            lay = Image.new('RGBA', (cv.n, cv.n), (0, 0, 0, 0))
            d = ImageDraw.Draw(lay)
            d.ellipse((cx - R, cy - R, cx + R, cy + R), fill=(10, 14, 24, 110))
            d.ellipse((cx - R, cy - R, cx + R, cy + R), outline=GOLD + (200,), width=int(2.4 * K))
            d.ellipse((cx - R * 0.8, cy - R * 0.8, cx + R * 0.8, cy + R * 0.8), outline=(255, 255, 255, 40), width=K)
            cv.img.alpha_composite(lay)
            for a_ in range(4):
                x = cx + math.cos(math.radians(90 * a_)) * R * 0.88
                y = cy + math.sin(math.radians(90 * a_)) * R * 0.88
                cv.poly([(x - 5 * K, y), (x, y - 5 * K), (x + 5 * K, y), (x, y + 5 * K)], GOLD_L, GOLD_D, outline=None)
    return make(size, size, f)
