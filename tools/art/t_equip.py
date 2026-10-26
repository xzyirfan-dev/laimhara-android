import sys
from lib import *
from equip import MAKERS
from PIL import Image
W=128
sheet=Image.new('RGBA',(W*7,W*9),(28,34,46,255))
for r,(name,fn) in enumerate(MAKERS.items()):
    for p in range(7):
        cv=fn(p)
        im=cv.save(f'/home/claude/work/proj/art/icons/eq_{name}_{p}.png',128)
        sheet.alpha_composite(im,(p*W,r*W))
sheet.save('/home/claude/shots/equip_sheet.png')
