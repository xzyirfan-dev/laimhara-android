"""Ikon perlengkapan: 9 slot x 7 tier, masing-masing siluet & hiasan berbeda."""
import math
from lib import *

METAL = rgb('9aa3b5')
METAL_D = rgb('4a5266')


def _wing(cv, cx, cy, s, col, k=1.0, n=5):
    """sayap berbulu (arah kanan; s=+1 kanan / -1 kiri)"""
    for i in range(n):
        L = (190 - i * 22) * k
        a = math.radians(-28 + i * 17)
        x0, y0 = cx, cy
        x1 = cx + s * math.cos(a) * L
        y1 = cy + math.sin(a) * L
        nx, ny = -math.sin(a) * 20 * k, math.cos(a) * 20 * k
        pts = [(x0, y0 - 6), (x1 + nx * 0.3 * s, y1 - 12), (x1 + s * 8, y1 + 6), (x0, y0 + 16)]
        cv.poly(pts, shade(col, 1.35), shade(col, 0.7), outline=shade(col, 0.3), ow=5, alpha=235)


def weapon(p):
    P = PAL[p]
    cv = Cv()
    ln = 20 + p * 9
    end = 400 + ln
    M, D, T, G = P['main'], P['dark'], P['trim'], P['glow']
    # sayap/bilah di belakang untuk tier tinggi
    if p >= 6:
        for k, (dy, L) in enumerate([(-35, 120), (-60, 95)]):
            cv.poly([(250, 240 + dy * 0.2), (300 + L, 215 + dy), (270 + L, 250 + dy * 0.6), (240, 262)], shade(G, 1.2), shade(G, 0.6), outline=shade(G, 0.3), ow=4, alpha=210)
    if p >= 5:
        for i in range(3):
            x = 290 + i * 46
            cv.glow_poly([(x, 262), (x + 12, 160 - i * 14), (x + 30, 262)], G, 0.7, 10)
            cv.poly([(x, 262), (x + 14, 170 - i * 14), (x + 30, 262)], shade(G, 1.4), shade(G, 0.6), outline=shade(G, 0.25), ow=4)
    # popor
    cv.poly([(40, 262), (150, 244), (165, 318), (62, 346)], shade(M, 0.9), shade(D, 0.9))
    cv.shine([(48, 262), (150, 248), (152, 268), (52, 282)], 60)
    cv.rrect((26, 256, 62, 340), 10, T, shade(T, 0.55), ow=6)
    # grip
    cv.poly([(172, 300), (222, 300), (212, 392), (160, 384)], shade(D, 1.1), shade(D, 0.55))
    # laras
    cv.rrect((312, 252, end, 290), 10, METAL, METAL_D)
    cv.rrect((312, 252, end, 266), 8, shade(METAL, 1.4), METAL, outline=None, ow=0)
    for i in range(p // 2 + 1):  # sirip pendingin
        x = 330 + i * 28
        cv.rrect((x, 240, x + 12, 302), 4, T, shade(T, 0.5), ow=5)
    if p >= 2:
        cv.rrect((312, 292, end - 30, 308), 6, METAL_D, shade(METAL_D, 0.6), ow=5)
    cv.rrect((end - 14, 238, end + 22, 304), 8, T, shade(T, 0.5), ow=6)
    cv.glow(end + 24, 271, 30, G, 0.9)
    cv.circle(end + 20, 271, 12, shade(G, 1.5), G, outline=None)
    # badan
    cv.rrect((140, 224, 330, 312), 18, M, D)
    cv.rrect((150, 228, 322, 244), 8, shade(M, 1.35), M, outline=None, ow=0)
    cv.rrect((150, 296, 322, 308), 6, T, shade(T, 0.5), outline=None, ow=0)
    cv.rrect((182, 252, 300, 280), 8, shade(D, 0.45), shade(D, 0.3), ow=4)
    cv.line([(190, 266), (292, 266)], G, 8)
    cv.glow(240, 266, 40, G, 0.5)
    # teropong
    cv.rrect((186, 176, 300, 218), 12, METAL_D, shade(METAL_D, 0.6))
    cv.rrect((290, 170, 322, 224), 8, T, shade(T, 0.5), ow=6)
    cv.circle(322, 197, 14, shade(G, 1.5), G, ow=5)
    cv.rrect((220, 214, 240, 232), 4, METAL_D, outline=None, ow=0)
    # sel energi
    cv.rrect((230, 312, 282, 376), 10, shade(D, 0.8), shade(D, 0.4))
    cv.rrect((238, 322, 274, 366), 6, shade(G, 1.2), shade(G, 0.55), ow=4)
    cv.glow(256, 344, 36, G, 0.55)
    if p >= 4:  # tanduk emas di atas
        for i in range(2):
            x = 335 + i * 55
            cv.poly([(x, 252), (x + 10, 190 - i * 10), (x + 32, 252)], shade(T, 1.3), shade(T, 0.6), outline=shade(T, 0.25), ow=5)
    if p == 3:  # rantai
        for i in range(5):
            cv.ellipse((60 + i * 22, 352 + (i % 2) * 8, 92 + i * 22, 376 + (i % 2) * 8), shade(METAL, 1.1), METAL_D, ow=5)
    cv.shadow(120, 18, 14)
    cv.rotate(36)
    return cv


def helm(p):
    P = PAL[p]
    cv = Cv()
    M, D, T, G, C = P['main'], P['dark'], P['trim'], P['glow'], P['cape']
    # belakang: tanduk/sayap/jambul
    if p == 2:
        for s in (-1, 1):
            cx = 256 + s * 118
            cv.poly([(cx - s * 20, 190), (cx + s * 70, 70), (cx + s * 90, 20), (cx + s * 44, 150), (cx + s * 22, 230)], shade(T, 1.3), shade(T, 0.6), outline=shade(T, 0.25), ow=5)
    if p == 4:
        for s in (-1, 1):
            cx = 256 + s * 120
            cv.poly([(cx - s * 10, 220), (cx + s * 62, 170), (cx + s * 96, 90), (cx + s * 110, 40), (cx + s * 68, 100), (cx + s * 40, 140), (cx + s * 16, 180)], shade(T, 1.4), shade(T, 0.65), outline=shade(T, 0.25), ow=5)
    if p == 6:
        for s in (-1, 1):
            _wing(cv, 256 + s * 120, 230, s, G, 0.95, 4)
    if p == 5:
        for i, (dx, h) in enumerate([(-120, 110), (-62, 170), (0, 200), (62, 170), (120, 110)]):
            cv.glow_poly([(256 + dx - 26, 190), (256 + dx, 190 - h), (256 + dx + 26, 190)], G, 0.65, 10)
            cv.poly([(256 + dx - 26, 200), (256 + dx, 190 - h), (256 + dx + 26, 200)], shade(G, 1.3), shade(G, 0.55), outline=shade(G, 0.25), ow=5)
    # kubah
    if p == 0:
        cv.ellipse((120, 96, 392, 360), shade(M, 1.1), D)
        cv.line([(256, 100), (256, 330)], shade(D, 0.7), 8)
        cv.poly([(130, 270), (382, 270), (392, 330), (120, 330)], shade(D, 1.2), shade(D, 0.7))
        for s in (-1, 1):  # kacamata
            cv.circle(256 + s * 62, 250, 40, METAL, METAL_D, ow=7)
            cv.circle(256 + s * 62, 250, 26, shade(G, 1.5), G, ow=4)
        cv.line([(130, 250), (216, 250)], shade(D, 0.5), 10)
        cv.line([(296, 250), (382, 250)], shade(D, 0.5), 10)
        cv.shine([(160, 150), (230, 112), (250, 130), (180, 190)], 90)
    else:
        cv.ellipse((112, 84, 400, 372), shade(M, 1.15), D)
        # pelat pipi
        for s in (-1, 1):
            x0 = 256 + s * 134
            cv.poly([(x0, 250), (x0 - s * 52, 250), (x0 - s * 70, 410), (x0 - s * 20, 440), (x0 + s * 4, 330)], M, D)
            cv.line([(x0 - s * 10, 280), (x0 - s * 44, 280)], T, 6)
        # celah wajah
        cv.poly([(186, 232), (326, 232), (318, 380), (256, 420), (194, 380)], shade(D, 0.35), (8, 6, 8), ow=6)
        cv.rrect((196, 258, 316, 290), 10, shade(G, 1.4) if p >= 2 else shade(T, 0.8), G if p >= 2 else shade(T, 0.5), ow=5)
        if p >= 2:
            cv.glow(256, 274, 60, G, 0.5)
        # pita dahi
        cv.poly([(116, 214), (396, 214), (400, 244), (112, 244)], T, shade(T, 0.55), ow=6)
        for x in range(150, 380, 46):
            cv.circle(x, 229, 6, shade(T, 1.5), shade(T, 0.7), outline=None)
        cv.line([(256, 94), (256, 214)], shade(T, 0.9), 12)
        cv.shine([(150, 140), (230, 100), (256, 120), (170, 200)], 85)
        if p == 1:  # pelindung hidung
            cv.poly([(240, 232), (272, 232), (268, 340), (244, 340)], T, shade(T, 0.55), ow=5)
        if p == 3:  # jambul + visor
            cv.poly([(236, 94), (276, 94), (300, 20), (212, 20)], shade(T, 1.2), shade(T, 0.6), outline=shade(T, 0.25), ow=5)
            cv.poly([(220, 40), (292, 40), (280, 90), (232, 90)], G, shade(G, 0.5), outline=None)
        if p == 4:
            cv.gem(256, 150, 28, rgb('ff3b2f'), 4)
        if p == 5:
            cv.gem(256, 160, 30, G, 5)
        if p == 6:
            cv.poly([(236, 94), (276, 94), (292, 30), (256, 4), (220, 30)], shade(G, 1.4), shade(G, 0.6), outline=shade(G, 0.3), ow=5)
            cv.glow(256, 120, 50, G, 0.7)
    cv.shadow(120, 16, 12)
    return cv


def armor(p):
    P = PAL[p]
    cv = Cv()
    M, D, T, G, C = P['main'], P['dark'], P['trim'], P['glow'], P['cape']
    if p == 6:
        for s in (-1, 1):
            _wing(cv, 256 + s * 70, 200, s, G, 1.0, 5)
    # bahu
    for s in (-1, 1):
        cx = 256 + s * 160
        if p >= 2:
            sp = 70 + p * 12
            cv.poly([(cx - s * 30, 150), (cx + s * 8, 150 - sp), (cx + s * 44, 150)], shade(T, 1.25), shade(T, 0.55), outline=shade(T, 0.25), ow=5)
        if p == 4:
            cv.poly([(cx - s * 10, 170), (cx + s * 62, 120), (cx + s * 80, 60), (cx + s * 24, 140)], shade(T, 1.4), shade(T, 0.65), outline=shade(T, 0.25), ow=5)
        if p == 0:
            cv.ellipse((cx - 56, 130, cx + 56, 210), shade(M, 1.0), D)
        else:
            cv.ellipse((cx - 70, 118, cx + 70, 226), shade(M, 1.2), D)
            cv.ellipse((cx - 52, 128, cx + 52, 196), shade(T, 1.0), shade(T, 0.55), ow=5)
            cv.shine([(cx - 50, 140), (cx + 10, 128), (cx + 20, 150), (cx - 40, 176)], 80)
    # badan
    body = [(142, 150), (370, 150), (394, 250), (350, 420), (162, 420), (118, 250)]
    body = [(160, 142), (352, 142), (372, 238), (342, 430), (170, 430), (140, 238)]
    cv.poly(body, shade(M, 1.1), D)
    # kerah
    cv.ellipse((196, 112, 316, 186), shade(D, 0.5), (10, 8, 10), ow=6)
    if p == 3:  # kerah bulu
        for i in range(9):
            x = 160 + i * 24
            cv.poly([(x, 150), (x + 14, 128), (x + 30, 156), (x + 18, 190)], (236, 240, 236), (170, 180, 170), outline=(90, 100, 90), ow=3)
    if p == 0:  # tali rompi
        cv.line([(200, 160), (256, 300), (312, 160)], D, 14)
        for i in range(5):
            y = 200 + i * 40
            cv.line([(222, y), (290, y + 8)], T, 6)
    else:
        cv.poly([(256, 160), (300, 200), (284, 330), (256, 360), (228, 330), (212, 200)], shade(M, 1.28), shade(M, 0.85), ow=6)
        cv.line([(256, 160), (256, 360)], T, 8)
        cv.poly([(164, 212), (212, 200), (228, 330), (184, 380)], shade(D, 1.2), D, outline=OUT, ow=5)
        cv.poly([(348, 212), (300, 200), (284, 330), (328, 380)], shade(D, 1.2), D, outline=OUT, ow=5)
    # inti energi
    cv.glow(256, 250, 54, G, 0.6)
    cv.gem(256, 250, 26 + p * 1.5, G if p != 4 else rgb('ff3b2f'), 6 if p < 5 else 5)
    # ikat pinggang + tasset
    cv.rrect((156, 374, 356, 412), 8, T, shade(T, 0.5), ow=6)
    cv.rrect((236, 370, 276, 416), 6, shade(T, 1.4), shade(T, 0.7), ow=5)
    for i in range(4):
        x = 168 + i * 46
        cv.poly([(x, 412), (x + 40, 412), (x + 34, 468), (x + 6, 468)], shade(D, 1.3), D, ow=5)
    if p >= 1:
        for x, y in [(190, 170), (322, 170), (186, 300), (326, 300)]:
            cv.circle(x, y, 6, shade(T, 1.5), shade(T, 0.7), outline=None)
    if p == 5:
        for x in (150, 362):
            cv.line([(x, 250), (x + (14 if x < 256 else -14), 330)], G, 6)
    cv.shadow(120, 16, 12)
    return cv


def gloves(p):
    P = PAL[p]
    cv = Cv()
    M, D, T, G = P['main'], P['dark'], P['trim'], P['glow']
    if p == 6:
        for s in (-1, 1):
            cv.poly([(256 + s * 80, 300), (256 + s * 190, 190), (256 + s * 150, 320)], shade(G, 1.3), shade(G, 0.6), outline=shade(G, 0.3), ow=4, alpha=220)
    # lengan/manset
    cv.poly([(170, 350), (350, 350), (364, 468), (156, 468)], shade(D, 1.2), D)
    cv.rrect((150, 338, 370, 392), 14, T, shade(T, 0.5), ow=6)
    for x in (186, 226, 266, 306):
        cv.circle(x, 365, 7, shade(T, 1.5), shade(T, 0.7), outline=None)
    # ibu jari
    cv.poly([(150, 300), (118, 250), (146, 216), (196, 262), (198, 310)], shade(M, 1.1), D)
    # telapak
    cv.rrect((156, 224, 366, 352), 26, shade(M, 1.15), D)
    # jari
    for i, (x, h) in enumerate([(160, 62), (206, 40), (252, 30), (298, 44)]):
        y0 = 222 - 70 + (0 if i else 14)
        top = 120 + (i in (0, 3)) * 24 + (i == 0) * 10
        cv.rrect((x, top, x + 50, 244), 18, shade(M, 1.2), D, ow=6)
        cv.line([(x + 6, top + 56), (x + 44, top + 56)], shade(D, 0.7), 5)
        if p >= 2:
            cv.poly([(x + 8, top + 4), (x + 25, top - 38 - p * 4), (x + 42, top + 4)], shade(T, 1.3), shade(T, 0.6), outline=shade(T, 0.25), ow=4)
        if p == 5:
            cv.poly([(x + 10, top + 6), (x + 25, top - 74), (x + 40, top + 6)], shade(G, 1.4), shade(G, 0.6), outline=shade(G, 0.3), ow=4)
    # punggung tangan
    cv.rrect((186, 262, 336, 340), 14, shade(D, 1.3), D, ow=5)
    cv.glow(262, 300, 40, G, 0.5)
    cv.gem(262, 300, 22, G, 4 if p != 4 else 6)
    cv.shine([(176, 240), (300, 230), (300, 250), (176, 262)], 70)
    cv.shadow(120, 16, 12)
    return cv


def boots(p):
    P = PAL[p]
    cv = Cv()
    M, D, T, G = P['main'], P['dark'], P['trim'], P['glow']
    if p >= 4:
        _wing(cv, 190, 230, -1, G if p == 6 else T, 0.62 if p == 4 else 0.7, 4)
    # sol
    cv.poly([(130, 410), (430, 410), (452, 450), (110, 462)], shade(D, 0.7), shade(D, 0.35), ow=6)
    if p >= 5:
        cv.line([(150, 454), (430, 446)], G, 8)
        cv.glow(300, 452, 60, G, 0.5)
    # batang + kaki
    cv.poly([(160, 80), (322, 80), (334, 300), (440, 340), (452, 410), (130, 410), (150, 300)], shade(M, 1.15), D)
    cv.shine([(176, 96), (240, 92), (246, 280), (186, 290)], 60)
    # manset
    cv.rrect((146, 70, 336, 130), 14, T, shade(T, 0.5), ow=6)
    cv.rrect((156, 142, 326, 160), 6, shade(D, 0.9), shade(D, 0.5), outline=None, ow=0)
    # tali/gesper
    for y in (210, 262):
        cv.rrect((158, y, 332, y + 24), 8, shade(D, 1.2), D, ow=5)
        cv.rrect((226, y - 2, 262, y + 26), 6, shade(T, 1.3), shade(T, 0.6), ow=4)
    # ujung sepatu
    cv.poly([(330, 330), (440, 340), (452, 410), (330, 410)], shade(M, 0.95), shade(D, 0.9), ow=6)
    cv.rrect((322, 322, 454, 352), 10, T, shade(T, 0.55), ow=5)
    if p >= 1:
        cv.poly([(132, 410), (112, 380), (160, 396)], shade(T, 1.2), shade(T, 0.55), outline=shade(T, 0.25), ow=4)
    if p >= 2:
        cv.poly([(430, 346), (500, 330), (454, 384)], shade(T, 1.3), shade(T, 0.6), outline=shade(T, 0.25), ow=4)
    if p >= 3:
        cv.gem(244, 120, 20, G, 4)
    cv.shadow(120, 14, 12)
    return cv


def cloak(p):
    P = PAL[p]
    cv = Cv()
    M, D, T, G, C = P['main'], P['dark'], P['trim'], P['glow'], P['cape']
    if p == 6:
        for s in (-1, 1):
            _wing(cv, 256 + s * 40, 170, s, G, 1.25, 6)
    if p == 0:
        col = (150, 80, 50)
    else:
        col = C
    body = [(170, 90), (342, 90), (380, 230), (436, 450), (384, 470), (330, 440), (290, 474), (256, 446), (222, 474), (182, 440), (128, 470), (76, 450), (132, 230)]
    if p == 5:  # tepi bergerigi
        body = [(170, 90), (342, 90), (380, 230), (440, 460), (400, 440), (372, 490), (340, 440), (300, 494), (256, 442), (212, 494), (172, 440), (140, 490), (112, 440), (72, 460), (132, 230)]
    cv.poly(body, shade(col, 1.35), shade(col, 0.45), outline=shade(col, 0.2), ow=7)
    # lipatan
    for x0, x1 in [(210, 190), (256, 256), (302, 322), (238, 150), (276, 366)]:
        cv.line([(x0, 130), (x1, 440)], shade(col, 0.4), 6, 150)
    cv.shine([(190, 110), (230, 110), (200, 430), (150, 420)], 55)
    # kerah + hiasan
    cv.rrect((150, 70, 362, 130), 22, T, shade(T, 0.5), ow=7)
    if p >= 1:
        cv.line([(100, 452), (180, 444)], T, 8)
        cv.line([(332, 444), (412, 452)], T, 8)
    # penjepit
    cv.glow(256, 100, 40, G, 0.6)
    cv.gem(256, 100, 24 + p, G if p not in (4,) else rgb('ff3b2f'), 6)
    cv.shadow(120, 14, 12)
    return cv


def belt(p):
    P = PAL[p]
    cv = Cv()
    M, D, T, G = P['main'], P['dark'], P['trim'], P['glow']
    band = [(40, 190), (472, 190), (472, 310), (40, 310)]
    cv.rrect((30, 190, 482, 310), 24, shade(M, 1.1), D, ow=8)
    cv.rrect((40, 200, 472, 222), 10, shade(M, 1.45), shade(M, 1.0), outline=None, ow=0)
    for x in range(60, 460, 40):
        cv.circle(x, 296, 6, shade(T, 1.5), shade(T, 0.7), outline=None)
    # kantong
    for x in (70, 372):
        cv.rrect((x, 270, x + 72, 372), 14, shade(D, 1.25), D, ow=6)
        cv.rrect((x + 4, 270, x + 68, 296), 8, T, shade(T, 0.5), ow=4)
    # gesper
    sh = [(256 - 66, 250), (256 - 34, 190 - 20), (256 + 34, 190 - 20), (256 + 66, 250), (256 + 34, 320 + 20), (256 - 34, 320 + 20)]
    if p >= 4:
        sh = [(190, 250), (222, 176), (290, 176), (322, 250), (290, 330), (222, 330)]
    cv.poly(sh, shade(T, 1.3), shade(T, 0.55), ow=8)
    cv.poly(pts_scale(sh, 256, 253, 0.7), shade(D, 1.1), shade(D, 0.4), ow=5)
    cv.glow(256, 253, 46, G, 0.6)
    cv.gem(256, 253, 24, G if p != 4 else rgb('ff3b2f'), 4 + (p % 3))
    if p >= 2:
        for s in (-1, 1):
            cv.poly([(256 + s * 76, 240), (256 + s * 130, 214), (256 + s * 122, 266), (256 + s * 76, 276)], shade(T, 1.2), shade(T, 0.55), ow=5)
    if p >= 5:
        for i in range(5):
            x = 120 + i * 68
            if abs(x - 256) > 90:
                cv.line([(x, 232), (x + 24, 232)], G, 6)
    cv.shadow(120, 14, 12)
    return cv


def neck(p):
    P = PAL[p]
    cv = Cv()
    M, D, T, G = P['main'], P['dark'], P['trim'], P['glow']
    # rantai
    pts = []
    for i in range(23):
        t = i / 22
        x = 110 + 292 * t
        y = 70 + 230 * (1 - (2 * t - 1) ** 2) * 0.9 + 0
        y = 80 + 220 * math.sin(math.pi * t) ** 1.5
        pts.append((x, y))
    for i, (x, y) in enumerate(pts):
        cv.ellipse((x - 15, y - 11, x + 15, y + 11), shade(T, 1.35), shade(T, 0.55), ow=5)
    cx, cy = 256, 320
    cv.glow(cx, cy + 30, 90, G, 0.4)
    if p == 0:  # taring/batu
        cv.poly([(cx, cy - 20), (cx + 40, cy + 40), (cx + 8, cy + 120), (cx - 36, cy + 50)], shade(M, 1.3), D)
    elif p == 1:  # cakram perunggu
        cv.circle(cx, cy + 50, 66, shade(M, 1.3), D, ow=8)
        cv.circle(cx, cy + 50, 44, shade(T, 1.1), shade(T, 0.5), ow=5)
        cv.gem(cx, cy + 50, 20, G, 4)
    elif p == 2:  # petir
        cv.poly([(cx + 24, cy - 30), (cx - 48, cy + 62), (cx - 4, cy + 62), (cx - 28, cy + 150), (cx + 52, cy + 38), (cx + 6, cy + 38)], shade(T, 1.4), shade(T, 0.7), outline=shade(T, 0.25), ow=6)
    elif p == 3:  # perisai daun
        cv.poly([(cx, cy - 20), (cx + 66, cy + 20), (cx + 50, cy + 110), (cx, cy + 150), (cx - 50, cy + 110), (cx - 66, cy + 20)], shade(M, 1.3), D, ow=7)
        cv.poly(pts_scale([(cx, cy - 20), (cx + 66, cy + 20), (cx + 50, cy + 110), (cx, cy + 150), (cx - 50, cy + 110), (cx - 66, cy + 20)], cx, cy + 62, 0.6), shade(G, 1.0), shade(G, 0.45), ow=4)
    elif p == 4:  # taring emas
        cv.poly([(cx - 20, cy - 16), (cx + 74, cy + 20), (cx + 36, cy + 150), (cx + 6, cy + 90)], shade(T, 1.4), shade(T, 0.65), outline=shade(T, 0.25), ow=6)
        cv.circle(cx - 6, cy + 40, 30, shade(T, 1.1), shade(T, 0.55), ow=6)
        cv.gem(cx - 6, cy + 40, 16, rgb('ff3b2f'), 4)
    elif p == 5:  # bola berduri
        for i in range(8):
            a = math.tau * i / 8
            cv.poly([(cx + math.cos(a - 0.22) * 40, cy + 56 + math.sin(a - 0.22) * 40), (cx + math.cos(a) * 90, cy + 56 + math.sin(a) * 90), (cx + math.cos(a + 0.22) * 40, cy + 56 + math.sin(a + 0.22) * 40)], shade(T, 1.2), shade(T, 0.55), outline=shade(T, 0.25), ow=4)
        cv.circle(cx, cy + 56, 48, shade(M, 1.4), D, ow=7)
        cv.gem(cx, cy + 56, 28, G, 5)
    else:  # berlian bersayap
        for s in (-1, 1):
            _wing(cv, cx + s * 30, cy + 40, s, G, 0.5, 4)
        cv.gem(cx, cy + 56, 54, G, 4)
    cv.shadow(120, 14, 12)
    return cv


def ring(p):
    P = PAL[p]
    cv = Cv()
    M, D, T, G = P['main'], P['dark'], P['trim'], P['glow']
    if p >= 4:
        for s in (-1, 1):
            cv.poly([(256 + s * 120, 300), (256 + s * 210, 200), (256 + s * 190, 310), (256 + s * 130, 350)], shade(T if p == 4 else G, 1.3), shade(T if p == 4 else G, 0.6), outline=shade(T, 0.25), ow=5)
    # cincin
    cv.ellipse((120, 190, 392, 450), shade(T, 1.4), shade(T, 0.5), ow=8)
    cv.ellipse((160, 232, 352, 410), (14, 10, 16), (30, 22, 30), ow=6)
    cv.shine([(140, 270), (170, 220), (200, 210), (160, 300)], 100)
    if p >= 1:
        for s in (-1, 1):
            cv.poly([(256 + s * 60, 220), (256 + s * 120, 190), (256 + s * 126, 250), (256 + s * 76, 262)], shade(M, 1.2), D, ow=5)
    # kepala cincin
    cv.poly([(196, 220), (316, 220), (344, 170), (168, 170)], shade(T, 1.4), shade(T, 0.55), ow=7)
    cv.glow(256, 150, 70, G, 0.6)
    cv.gem(256, 140, 44, G if p != 4 else rgb('ff3b2f'), [4, 6, 5, 6, 8, 5, 4][p])
    if p == 5:
        for s in (-1, 1):
            cv.poly([(256 + s * 38, 120), (256 + s * 80, 60), (256 + s * 60, 130)], shade(G, 1.3), shade(G, 0.6), outline=shade(G, 0.25), ow=4)
    cv.shadow(120, 14, 12)
    return cv


MAKERS = {"weapon": weapon, "helm": helm, "armor": armor, "gloves": gloves, "boots": boots, "cloak": cloak, "belt": belt, "neck": neck, "ring": ring}
