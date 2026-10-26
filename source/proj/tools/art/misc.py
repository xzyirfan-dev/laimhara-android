"""Ikon permata, consumable, skill, glyph HUD."""
import math
from lib import *
from PIL import ImageFont

FONT_B = '/usr/share/fonts/truetype/google-fonts/Poppins-Bold.ttf'
GOLD = rgb('f0c860')
GOLD_D = rgb('8a6420')


def text(cv, s, cx, cy, size, col=(255, 255, 255), outline=OUT, ow=8):
    f = ImageFont.truetype(FONT_B, size)
    d = ImageDraw.Draw(cv.img)
    d.text((cx, cy), s, font=f, fill=tuple(col) + (255,), anchor='mm', stroke_width=ow, stroke_fill=tuple(outline) + (255,))
    return cv


# ================= PERMATA =================
GEMC = {"ruby": rgb('f0283a'), "topaz": rgb('ffc928'), "amethyst": rgb('b24cff'), "emerald": rgb('26e069'), "sapphire": rgb('3d8cff')}


def sparkle(cv, x, y, r, col=(255, 255, 255)):
    cv.poly([(x, y - r), (x + r * 0.22, y - r * 0.22), (x + r, y), (x + r * 0.22, y + r * 0.22), (x, y + r), (x - r * 0.22, y + r * 0.22), (x - r, y), (x - r * 0.22, y - r * 0.22)], col, col, outline=None)


def gem_icon(kind, grade):
    cv = Cv()
    c = GEMC[kind]
    cx, cy = 256, 262
    k = 0.78 + grade * 0.055
    if grade == 1:  # kasar: kusam dan tidak simetris
        c = mix(c, (110, 110, 110), 0.5)
    if grade >= 3:
        cv.glow(cx, cy, 150 * k, GEMC[kind], 0.25 + 0.1 * grade)
    if kind == "ruby":
        pts = [(cx - 120 * k, cy - 20 * k), (cx - 70 * k, cy - 110 * k), (cx + 70 * k, cy - 110 * k), (cx + 120 * k, cy - 20 * k), (cx, cy + 130 * k)]
    elif kind == "topaz":
        pts = [(cx, cy - 135 * k), (cx + 100 * k, cy), (cx, cy + 135 * k), (cx - 100 * k, cy)]
    elif kind == "amethyst":
        pts = [(cx - 70 * k, cy + 120 * k), (cx - 90 * k, cy - 20 * k), (cx - 30 * k, cy - 130 * k), (cx + 30 * k, cy - 130 * k), (cx + 90 * k, cy - 20 * k), (cx + 70 * k, cy + 120 * k)]
    elif kind == "emerald":
        a, b = 100 * k, 125 * k
        pts = [(cx - a * 0.6, cy - b), (cx + a * 0.6, cy - b), (cx + a, cy - b * 0.55), (cx + a, cy + b * 0.55), (cx + a * 0.6, cy + b), (cx - a * 0.6, cy + b), (cx - a, cy + b * 0.55), (cx - a, cy - b * 0.55)]
    else:  # sapphire: tetes
        pts = [(cx, cy - 140 * k)]
        for i in range(0, 21):
            a = math.pi * (0.15 + 0.7 * i / 20) * 1.0
            pts.append((cx + math.cos(math.pi / 2 + (i - 10) / 10 * 2.2) * 105 * k, cy + 25 * k + math.sin(math.pi / 2 + (i - 10) / 10 * 2.2) * 105 * k))
    if grade == 1:
        pts = [(x + ((i * 37) % 23 - 11), y + ((i * 53) % 19 - 9)) for i, (x, y) in enumerate(pts)]
    cv.poly(pts, shade(c, 1.4), shade(c, 0.5), outline=shade(c, 0.2), ow=8)
    cxm = sum(p[0] for p in pts) / len(pts)
    cym = sum(p[1] for p in pts) / len(pts)
    if grade >= 2:
        inner = pts_scale(pts, cxm, cym, 0.6)
        cv.poly(inner, shade(c, 1.2), shade(c, 0.75), outline=shade(c, 0.35), ow=4)
        for p in pts:  # garis faset
            cv.line([p, (cxm + (p[0] - cxm) * 0.6, cym + (p[1] - cym) * 0.6)], shade(c, 0.35), 4, 180)
    cv.shine([(cxm - 70 * k, cym - 60 * k), (cxm + 10 * k, cym - 100 * k), (cxm - 10 * k, cym - 10 * k), (cxm - 62 * k, cym + 10 * k)], 100 if grade > 1 else 40)
    if grade >= 4:
        sparkle(cv, cx + 110, cy - 120, 30)
        sparkle(cv, cx - 120, cy + 70, 20)
    if grade >= 5:
        sparkle(cv, cx + 120, cy + 90, 24)
        cv.arc((cx - 175, cy - 175, cx + 175, cy + 175), 200, 340, rgb('ffe28a'), 8)
        cv.arc((cx - 175, cy - 175, cx + 175, cy + 175), 20, 160, rgb('ffe28a'), 8)
    cv.shadow(120, 12, 10)
    return cv


# ================= CONSUMABLE =================
def flask(col, big=True):
    cv = Cv()
    cv.glow(256, 330, 150, col, 0.35)
    cv.poly([(224, 80), (288, 80), (292, 190), (222, 190)], (200, 220, 235), (120, 150, 170), ow=7, alpha=230)
    cv.rrect((214, 56, 298, 96), 10, rgb('9a6a3a'), rgb('5a381c'), ow=6)
    cv.ellipse((106, 170, 406, 470), (225, 235, 245), (140, 160, 185), ow=8, alpha=235)
    cv.ellipse((126, 255, 386, 458), shade(col, 1.35), shade(col, 0.45), outline=None, mode='v')
    cv.line([(150, 258), (362, 258)], shade(col, 1.6), 8)
    cv.shine([(150, 230), (200, 200), (190, 330), (156, 340)], 120)
    for x, y, r in [(250, 360, 12), (300, 330, 8), (210, 400, 9)]:
        cv.circle(x, y, r, shade(col, 1.7), shade(col, 1.3), outline=None)
    cv.shadow(120, 12, 10)
    return cv


def scroll(col, glyph='tp'):
    cv = Cv()
    cv.glow(256, 256, 160, col, 0.3)
    cv.rrect((120, 110, 392, 410), 18, rgb('ecdcae'), rgb('b99a58'), ow=8)
    for y in (96, 394):
        cv.rrect((100, y, 412, y + 40), 18, rgb('9a6a3a'), rgb('5a381c'), ow=7)
        cv.circle(98, y + 20, 16, rgb('e0b560'), rgb('8a6420'), ow=5)
        cv.circle(414, y + 20, 16, rgb('e0b560'), rgb('8a6420'), ow=5)
    cv.circle(256, 258, 78, shade(col, 1.0), shade(col, 0.45), ow=6, alpha=230)
    cv.circle(256, 258, 56, (255, 255, 255), shade(col, 1.4), outline=shade(col, 0.4), ow=5, alpha=230)
    if glyph == 'tp':
        cv.poly([(256, 200), (292, 270), (256, 252), (220, 270)], shade(col, 0.6), shade(col, 0.4), outline=None)
        cv.line([(256, 290), (256, 318)], shade(col, 0.5), 10)
    else:
        for i in range(3):
            cv.arc((256 - 20 - i * 14, 258 - 20 - i * 14, 256 + 20 + i * 14, 258 + 20 + i * 14), 30 + i * 40, 330 - i * 20, shade(col, 0.5), 8)
    for y in (160, 190):
        cv.line([(150, y), (210, y)], rgb('9a7a3a'), 6, 160)
        cv.line([(302, y), (362, y)], rgb('9a7a3a'), 6, 160)
    cv.shadow(120, 12, 10)
    return cv


def capsule():
    cv = Cv()
    cv.glow(256, 256, 170, rgb('ffd24d'), 0.45)
    cv.rrect((90, 170, 422, 342), 86, rgb('ffe28a'), rgb('d28a1c'), ow=9)
    cv.rrect((90, 170, 256, 342), 86, rgb('ff7a5a'), rgb('b02a1c'), outline=None, ow=0)
    cv.rrect((90, 170, 422, 342), 86, None, None, outline=OUT, ow=9)
    cv.line([(256, 172), (256, 340)], OUT, 8)
    cv.shine([(130, 190), (400, 190), (400, 220), (130, 226)], 110)
    text(cv, 'x2', 256, 262, 96, (255, 255, 255), OUT, 10)
    cv.shadow(120, 12, 10)
    return cv


def shield_token(col, label, gold=False):
    cv = Cv()
    cv.glow(256, 256, 170, col, 0.4)
    sh = [(256, 70), (410, 120), (396, 300), (256, 450), (116, 300), (102, 120)]
    cv.poly(sh, shade(col, 1.35), shade(col, 0.5), outline=OUT, ow=9)
    cv.poly(pts_scale(sh, 256, 270, 0.78), shade(col, 1.1), shade(col, 0.65), outline=shade(col, 0.3), ow=5)
    cv.line([(256, 82), (256, 440)], (255, 255, 255), 5, 60)
    if label:
        text(cv, label, 256, 260, 108 if len(label) < 4 else 80, (255, 250, 220), OUT, 12)
    cv.shine([(140, 130), (240, 100), (240, 200), (150, 250)], 80)
    cv.shadow(120, 12, 10)
    return cv


def stone(col):
    cv = Cv()
    cv.glow(256, 256, 160, col, 0.5)
    pts = [(256, 70), (392, 150), (410, 300), (320, 440), (180, 440), (100, 300), (120, 150)]
    cv.poly(pts, shade(col, 1.5), shade(col, 0.45), ow=9)
    cv.poly(pts_scale(pts, 256, 270, 0.6), shade(col, 1.25), shade(col, 0.7), outline=shade(col, 0.3), ow=4)
    cv.shine([(150, 150), (250, 100), (240, 230), (160, 260)], 100)
    sparkle(cv, 380, 120, 30)
    cv.shadow(120, 12, 10)
    return cv


def orb_jewel(col, grade):
    cv = Cv()
    cv.glow(256, 256, 120 + grade * 14, col, 0.45 + grade * 0.08)
    cv.circle(256, 262, 140, shade(col, 1.5), shade(col, 0.4), ow=9, mode='d')
    cv.circle(256, 262, 100, shade(col, 1.2), shade(col, 0.55), outline=shade(col, 0.3), ow=4)
    cv.shine([(160, 180), (250, 130), (260, 200), (190, 260)], 110)
    for i in range(grade):
        a = math.radians(-90 + (i - (grade - 1) / 2) * 24)
        cv.circle(256 + math.cos(a) * 190, 262 + math.sin(a) * 190, 12, rgb('ffe28a'), rgb('c8901c'), ow=4)
    cv.shadow(120, 12, 10)
    return cv


def coin(col, mark):
    cv = Cv()
    cv.glow(256, 256, 150, col, 0.35)
    cv.circle(256, 262, 170, shade(col, 1.5), shade(col, 0.45), ow=9)
    cv.circle(256, 262, 138, shade(col, 1.1), shade(col, 0.7), outline=shade(col, 0.3), ow=6)
    text(cv, mark, 256, 266, 160, shade(col, 1.7), shade(col, 0.3), 8)
    cv.shine([(130, 190), (240, 120), (250, 160), (150, 240)], 100)
    cv.shadow(120, 12, 10)
    return cv


def empty_slot(name):
    """siluet redup untuk slot kosong"""
    from equip import MAKERS
    cv = MAKERS[name](0)
    im = cv.img.copy()
    a = im.getchannel('A').point(lambda v: min(255, v // 2))
    flat = Image.new('RGBA', im.size, (120, 140, 170, 255))
    flat.putalpha(a)
    cv.img = flat
    return cv


# ================= SKILL (medali bulat) =================
def medal(col, drawfn):
    cv = Cv()
    cv.circle(256, 256, 236, shade(col, 0.5), shade(col, 0.2), ow=8)
    cv.circle(256, 256, 214, rgb('0e1420'), rgb('1c2740'), outline=None)
    cv.glow(256, 256, 160, col, 0.5)
    drawfn(cv, col)
    cv.arc((20, 20, 492, 492), 0, 360, GOLD, 10)
    cv.arc((36, 36, 476, 476), 200, 300, rgb('fff4c0'), 6)
    return cv


def sk_marks(cv, c):
    cv.arc((120, 120, 392, 392), 0, 360, shade(c, 1.4), 16)
    cv.circle(256, 256, 40, shade(c, 1.5), c, ow=6)
    for a in range(4):
        r = math.radians(90 * a)
        cv.line([(256 + math.cos(r) * 90, 256 + math.sin(r) * 90), (256 + math.cos(r) * 170, 256 + math.sin(r) * 170)], shade(c, 1.4), 16)


def sk_snipe(cv, c):
    cv.arc((100, 100, 412, 412), 0, 360, shade(c, 1.4), 12)
    cv.line([(256, 60), (256, 452)], shade(c, 1.3), 8)
    cv.line([(60, 256), (452, 256)], shade(c, 1.3), 8)
    cv.circle(256, 256, 22, rgb('ff3b2f'), rgb('b01c14'), ow=5)
    for i in range(3):
        cv.line([(256 + 40 + i * 30, 240 - i * 6), (256 + 40 + i * 30, 272 + i * 6)], shade(c, 1.5), 6)


def sk_pen(cv, c):
    cv.rrect((290, 120, 330, 392), 6, rgb('8d97aa'), rgb('3e4658'), ow=6)
    cv.poly([(80, 262), (300, 210), (300, 300)], shade(c, 1.5), shade(c, 0.6), ow=7)
    cv.poly([(300, 218), (420, 256), (300, 294)], shade(c, 1.2), shade(c, 0.5), ow=5, alpha=200)
    cv.line([(110, 256), (300, 256)], (255, 255, 255), 5, 180)


def sk_power(cv, c):
    cv.glow(256, 256, 130, rgb('ffcf5a'), 0.8)
    pts = []
    for i in range(16):
        a = math.tau * i / 16
        r = 170 if i % 2 == 0 else 85
        pts.append((256 + math.cos(a) * r, 256 + math.sin(a) * r))
    cv.poly(pts, rgb('fff1a8'), rgb('ff8a1c'), outline=rgb('8a3a0a'), ow=7)
    cv.circle(256, 256, 54, (255, 255, 255), rgb('ffd25a'), outline=None)


def sk_shield(cv, c):
    cv.circle(256, 256, 160, shade(c, 1.3), shade(c, 0.5), outline=shade(c, 0.2), ow=8, alpha=110)
    cv.arc((96, 96, 416, 416), 0, 360, shade(c, 1.5), 12)
    sh = [(256, 140), (350, 176), (340, 290), (256, 380), (172, 290), (162, 176)]
    cv.poly(sh, shade(c, 1.5), shade(c, 0.6), outline=OUT, ow=7)
    cv.poly([(256, 160), (256, 360), (190, 280), (184, 190)], (255, 255, 255), shade(c, 1.3), outline=None, alpha=80)


def sk_semi(cv, c):
    for i in range(3):
        y = 160 + i * 90
        cv.rrect((120, y - 22, 330, y + 22), 12, rgb('c9ced8'), rgb('5a6272'), ow=6)
        cv.poly([(330, y - 22), (410, y), (330, y + 22)], rgb('ffb347'), rgb('c45a12'), ow=6)
        cv.line([(70, y), (118, y)], shade(c, 1.4), 8, 200)


def sk_frozen(cv, c):
    for i in range(6):
        a = math.radians(60 * i)
        ex, ey = 256 + math.cos(a) * 170, 256 + math.sin(a) * 170
        cv.line([(256, 256), (ex, ey)], (220, 245, 255), 16)
        for t, L in [(0.55, 50), (0.8, 34)]:
            mx, my = 256 + math.cos(a) * 170 * t, 256 + math.sin(a) * 170 * t
            for s in (-1, 1):
                b = a + s * math.radians(50)
                cv.line([(mx, my), (mx + math.cos(b) * L, my + math.sin(b) * L)], (220, 245, 255), 10)
    cv.circle(256, 256, 34, (255, 255, 255), rgb('8fd8ff'), ow=5)


def sk_air(cv, c):
    for i, (x, y) in enumerate([(150, 170), (256, 120), (362, 190)]):
        cv.poly([(x - 18, y - 70), (x + 18, y - 70), (x + 24, y + 40), (x, y + 80), (x - 24, y + 40)], rgb('c9ced8'), rgb('5a6272'), ow=6)
        cv.poly([(x - 24, y + 20), (x - 50, y + 60), (x - 22, y + 50)], rgb('ff5a3a'), rgb('9a1c10'), ow=4)
        cv.poly([(x + 24, y + 20), (x + 50, y + 60), (x + 22, y + 50)], rgb('ff5a3a'), rgb('9a1c10'), ow=4)
        cv.glow(x, y + 96, 36, rgb('ff9a3a'), 0.9)
    for i in range(4):
        cv.circle(120 + i * 90, 400, 18, rgb('ff9a3a'), rgb('c4421c'), outline=None)


def sk_fire(cv, c):
    cv.glow(256, 300, 150, rgb('ff8a2a'), 0.9)
    f = [(256, 60), (330, 170), (390, 260), (350, 390), (256, 450), (160, 390), (122, 260), (190, 170), (220, 220)]
    cv.poly(f, rgb('ffcf5a'), rgb('e8321c'), outline=rgb('7a1a0a'), ow=8)
    cv.poly(pts_scale(f, 256, 330, 0.62), rgb('fff4b0'), rgb('ff9a2a'), outline=None)


SKILLS = {
    "marks": (rgb('ffd05a'), sk_marks), "snipe": (rgb('5ad0ff'), sk_snipe), "pen": (rgb('ff8a5a'), sk_pen),
    "power": (rgb('ff7a2a'), sk_power), "shield": (rgb('5ab4ff'), sk_shield), "semi": (rgb('ffb03a'), sk_semi),
    "frozen": (rgb('7ad8ff'), sk_frozen), "air": (rgb('ff6a4a'), sk_air), "fire": (rgb('ff5a1a'), sk_fire),
}


# ================= GLYPH HUD (emas) =================
def glyph(fn):
    cv = Cv()
    fn(cv)
    cv.shadow(160, 8, 6)
    return cv


def _g(cv, pts, c1=rgb('ffeaa0'), c2=GOLD_D, **kw):
    cv.poly(pts, c1, c2, outline=rgb('3a2408'), ow=8, **kw)


def g_bag(cv):
    cv.rrect((120, 170, 392, 440), 60, rgb('ffeaa0'), GOLD_D, outline=rgb('3a2408'), ow=9)
    cv.rrect((190, 80, 322, 190), 50, None, None, outline=rgb('3a2408'), ow=26)
    cv.rrect((190, 80, 322, 190), 50, None, None, outline=rgb('d9b060'), ow=12)
    cv.rrect((150, 290, 362, 372), 20, rgb('c99a3c'), rgb('7a5418'), ow=6)
    cv.rrect((226, 270, 286, 330), 10, rgb('fff4c0'), rgb('c8901c'), ow=6)


def g_char(cv):
    cv.circle(256, 160, 80, rgb('ffeaa0'), GOLD_D, ow=9)
    cv.poly([(110, 440), (130, 290), (200, 250), (312, 250), (382, 290), (402, 440)], rgb('ffeaa0'), GOLD_D, outline=rgb('3a2408'), ow=9)
    cv.line([(256, 270), (256, 440)], rgb('3a2408'), 8, 160)


def g_skill(cv):
    pts = []
    for i in range(10):
        a = math.radians(-90 + 36 * i)
        r = 190 if i % 2 == 0 else 80
        pts.append((256 + math.cos(a) * r, 266 + math.sin(a) * r))
    _g(cv, pts)


def g_quest(cv):
    cv.rrect((130, 70, 382, 440), 20, rgb('f3e4b0'), rgb('b8985a'), outline=rgb('3a2408'), ow=9)
    for y in (200, 270, 340):
        cv.line([(180, y), (332, y)], rgb('7a5a22'), 12)
    cv.poly([(238, 110), (274, 110), (268, 170), (244, 170)], rgb('e8321c'), rgb('9a1c10'), ow=5)
    cv.circle(256, 188, 10, rgb('e8321c'), rgb('9a1c10'), ow=3)


def g_map(cv):
    cv.circle(256, 256, 190, rgb('ffeaa0'), GOLD_D, ow=9)
    cv.circle(256, 256, 140, rgb('1a2540'), rgb('2a3d66'), outline=rgb('3a2408'), ow=6)
    cv.poly([(256, 120), (292, 256), (256, 392), (220, 256)], rgb('ff6a4a'), rgb('9a1c10'), ow=6)
    cv.poly([(120, 256), (256, 220), (392, 256), (256, 292)], rgb('fff1b0'), rgb('c8901c'), ow=6, alpha=230)
    cv.circle(256, 256, 20, rgb('ffffff'), rgb('c8901c'), ow=5)


def g_scroll(cv):
    cv.rrect((130, 100, 382, 400), 16, rgb('f3e4b0'), rgb('b8985a'), outline=rgb('3a2408'), ow=9)
    for y in (84, 384):
        cv.rrect((104, y, 408, y + 44), 20, rgb('c99a3c'), rgb('7a5418'), outline=rgb('3a2408'), ow=8)
    cv.circle(256, 250, 52, rgb('5ad0ff'), rgb('1c6a9a'), ow=7)
    cv.line([(256, 214), (256, 286)], (255, 255, 255), 10)


def g_gear(cv):
    pts = []
    for i in range(16):
        a = math.tau * i / 16
        r = 190 if (i // 1) % 2 == 0 else 150
        pts.append((256 + math.cos(a) * r, 256 + math.sin(a) * r))
    pts2 = []
    for i in range(8):
        a0 = math.tau * i / 8
        for da, r in [(-0.16, 150), (-0.12, 196), (0.12, 196), (0.16, 150)]:
            pts2.append((256 + math.cos(a0 + da) * r, 256 + math.sin(a0 + da) * r))
    _g(cv, pts2)
    cv.circle(256, 256, 120, rgb('ffeaa0'), GOLD_D, ow=8)
    cv.circle(256, 256, 56, (14, 20, 32), rgb('2a3d66'), outline=rgb('3a2408'), ow=7)


def g_anvil(cv):
    _g(cv, [(70, 190), (440, 190), (400, 250), (320, 262), (330, 330), (400, 390), (400, 430), (112, 430), (112, 390), (182, 330), (192, 262), (112, 250)])
    cv.poly([(380, 70), (430, 110), (250, 250), (210, 210)], rgb('9aa3b5'), rgb('3e4658'), ow=8)
    cv.poly([(190, 80), (300, 80), (320, 140), (170, 140)], rgb('c9ced8'), rgb('5a6272'), ow=8)


def g_potion(cv):
    cv.ellipse((130, 190, 382, 440), rgb('ffeaa0'), GOLD_D, ow=9)
    cv.rrect((222, 80, 290, 210), 12, rgb('ffeaa0'), GOLD_D, ow=8)


def g_auto(cv):
    cv.arc((100, 100, 412, 412), 30, 300, rgb('ffeaa0'), 36)
    cv.poly([(380, 150), (440, 250), (320, 250)], rgb('ffeaa0'), GOLD_D, ow=7)
    text(cv, 'A', 256, 262, 170, rgb('ffeaa0'), rgb('3a2408'), 10)


def g_hunt(cv):
    cv.arc((90, 90, 422, 422), 0, 360, rgb('ffeaa0'), 26)
    cv.line([(256, 40), (256, 190)], rgb('ffeaa0'), 26)
    cv.line([(256, 322), (256, 472)], rgb('ffeaa0'), 26)
    cv.line([(40, 256), (190, 256)], rgb('ffeaa0'), 26)
    cv.line([(322, 256), (472, 256)], rgb('ffeaa0'), 26)
    cv.circle(256, 256, 40, rgb('ff6a4a'), rgb('9a1c10'), ow=7)


def g_atk(cv):
    from equip import weapon
    w = weapon(5)
    cv.img.alpha_composite(w.img)


def g_close(cv):
    cv.line([(110, 110), (402, 402)], rgb('3a2408'), 70)
    cv.line([(402, 110), (110, 402)], rgb('3a2408'), 70)
    cv.line([(110, 110), (402, 402)], rgb('ffeaa0'), 46)
    cv.line([(402, 110), (110, 402)], rgb('ffeaa0'), 46)


def g_back(cv):
    _g(cv, [(80, 256), (250, 90), (250, 190), (440, 190), (440, 322), (250, 322), (250, 422)])


def g_chat(cv):
    cv.rrect((60, 90, 452, 360), 60, rgb('ffeaa0'), GOLD_D, outline=rgb('3a2408'), ow=9)
    cv.poly([(130, 340), (110, 450), (230, 350)], rgb('e8cf80'), GOLD_D, ow=8)
    for x in (160, 256, 352):
        cv.circle(x, 225, 24, rgb('3a2408'), rgb('3a2408'), outline=None)


def g_save(cv):
    cv.rrect((80, 80, 432, 432), 30, rgb('ffeaa0'), GOLD_D, outline=rgb('3a2408'), ow=9)
    cv.rrect((150, 80, 362, 200), 12, rgb('3a2408'), rgb('3a2408'), outline=None)
    cv.rrect((140, 270, 372, 432), 14, rgb('fff8dc'), rgb('c8b070'), outline=rgb('3a2408'), ow=7)


def g_plus(cv):
    cv.line([(256, 100), (256, 412)], rgb('ffeaa0'), 60)
    cv.line([(100, 256), (412, 256)], rgb('ffeaa0'), 60)


def g_sell(cv):
    cv.circle(256, 256, 180, rgb('ffeaa0'), GOLD_D, ow=9)
    text(cv, '$', 256, 266, 230, rgb('3a2408'), rgb('ffeaa0'), 4)


def g_socket(cv):
    from lib import Cv as _C
    cv.gem(256, 256, 150, rgb('5ab4ff'), 6)


def g_up(cv):
    _g(cv, [(256, 70), (420, 250), (320, 250), (320, 440), (192, 440), (192, 250), (92, 250)])


def g_info(cv):
    cv.circle(256, 256, 190, rgb('ffeaa0'), GOLD_D, ow=9)
    text(cv, 'i', 256, 266, 240, rgb('3a2408'), rgb('ffeaa0'), 4)


GLYPHS = {"bag": g_bag, "char": g_char, "skill": g_skill, "quest": g_quest, "map": g_map, "scroll": g_scroll,
          "gear": g_gear, "anvil": g_anvil, "potion": g_potion, "auto": g_auto, "hunt": g_hunt, "close": g_close,
          "back": g_back, "chat": g_chat, "save": g_save, "plus": g_plus, "sell": g_sell, "socket": g_socket, "up": g_up, "info": g_info}
