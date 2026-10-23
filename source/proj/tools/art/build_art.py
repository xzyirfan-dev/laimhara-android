import os, sys
sys.path.insert(0, os.path.dirname(__file__))
from lib import *
import equip, misc, frames
from PIL import Image
OUT = '/home/claude/work/proj/art'
os.makedirs(OUT + '/icons', exist_ok=True)
os.makedirs(OUT + '/ui', exist_ok=True)
I = OUT + '/icons/'
U = OUT + '/ui/'
sheet = []
def ic(name, cv, fit=True, size=128):
    im = cv.save(I + name + '.png', size, fit=fit)
    sheet.append((name, im))

for slot, fn in equip.MAKERS.items():
    for p in range(7):
        ic(f'eq_{slot}_{p}', fn(p))
for slot in equip.MAKERS:
    ic(f'slot_{slot}', misc.empty_slot(slot))
for k in misc.GEMC:
    for g in range(1, 6):
        ic(f'gem_{k}_{g}', misc.gem_icon(k, g))
ic('hp', misc.flask(rgb('ff3040')))
ic('mp', misc.flask(rgb('3d8cff')))
ic('tp', misc.scroll(rgb('5ad0ff'), 'tp'))
ic('warp', misc.scroll(rgb('c05aff'), 'warp'))
ic('capsule', misc.capsule())
ic('safety', misc.shield_token(rgb('4aa8ff'), ''))
ic('w50', misc.shield_token(rgb('c98a3a'), '50%'))
ic('w100', misc.shield_token(rgb('f0c040'), '100%'))
ic('gem', misc.stone(rgb('9aa3b5')))
for i, c in enumerate(['#6a7a9a', '#4aa8ff', '#b05aff', '#ffb02a']):
    ic(f'aeth{i+1}', misc.orb_jewel(rgb(c[1:]), 4 - i))
ic('laima', misc.coin(rgb('f0c860'), 'L'))
ic('karu', misc.coin(rgb('c04aa0'), 'K'))
for sid, (c, fn) in misc.SKILLS.items():
    ic(f'sk_{sid}', misc.medal(c, fn), fit=False)
for name, fn in misc.GLYPHS.items():
    ic(f'g_{name}', misc.glyph(fn))

# ---- UI ----
def sv(name, im): im.save(U + name + '.png')
sv('panel', frames.panel(128, 128))
sv('panel_dark', frames.panel(128, 128, top=rgb('10151f'), bot=rgb('080b12'), alpha=250))
sv('panel_tip', frames.panel(128, 128, top=rgb('1c2438'), bot=rgb('0a0e18'), edge=rgb('8a7040'), alpha=250, ornament=False))
sv('panel_hud', frames.panel(96, 96, top=rgb('1a2236'), bot=rgb('0b0f18'), alpha=190, ornament=False, rad=10))
sv('inset', frames.inset(64, 64))
sv('title', frames.titlebar(256, 56))
for k in ['normal', 'hover', 'pressed', 'disabled', 'gold', 'gold_p', 'red', 'green']:
    sv('btn_' + k, frames.button(k))
sv('slot', frames.slot(None))
for i, c in enumerate(equip_cols := __import__('item_cols').COLS):
    sv(f'slot_r{i}', frames.slot(c))
sv('bar_frame', frames.bar_frame())
sv('bar_hp', frames.bar_fill(rgb('ff5a50'), rgb('a0121a')))
sv('bar_mp', frames.bar_fill(rgb('5ab4ff'), rgb('1a4aa8')))
sv('bar_xp', frames.bar_fill(rgb('ffe27a'), rgb('d29a1c')))
sv('bar_tg', frames.bar_fill(rgb('ff7a3a'), rgb('b01c0a')))
sv('pad_atk', frames.circle_pad(rgb('e8863a'), rgb('d04a2a'), rgb('6a1a10'), 256, rgb('ff6a2a')))
sv('pad_skill', frames.circle_pad(rgb('d9b060'), rgb('24365e'), rgb('0e1626'), 192))
sv('pad_skill_on', frames.circle_pad(rgb('7affb0'), rgb('1e5a3a'), rgb('0a2a1c'), 192, rgb('4aff8a')))
sv('pad_menu', frames.circle_pad(rgb('9aa8c4'), rgb('2a3a5c'), rgb('10182a'), 160))
sv('pad_quick', frames.circle_pad(rgb('d9b060'), rgb('2a2030'), rgb('0e0a14'), 160))
sv('ring_portrait', frames.ring(256, 0.84))
sv('ring_map', frames.ring(512, 0.9, ticks=True))
sv('tab', frames.tab(False))
sv('tab_on', frames.tab(True))
sv('pill', frames.pill())
sv('divider', frames.divider())
sv('soft', frames.soft_circle(128))
sv('joy_base', frames.joy(256, False))
sv('joy_knob', frames.joy(160, True))

# kontak sheet ikon
cols = 16
W = 96
rows = (len(sheet) + cols - 1) // cols
sh = Image.new('RGBA', (cols * W, rows * W), (28, 34, 46, 255))
for i, (n, im) in enumerate(sheet):
    sh.alpha_composite(im.resize((W, W), Image.LANCZOS), ((i % cols) * W, (i // cols) * W))
sh.save('/home/claude/shots/icons_sheet.png')
print(len(sheet), 'ikon')
