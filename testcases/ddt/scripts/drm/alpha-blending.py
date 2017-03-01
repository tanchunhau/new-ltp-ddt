#!/usr/bin/python3

import pykms
import time
import random

# This hack makes drm initialize the fbcon, setting up the default connector
card = pykms.Card()
card = 0

card = pykms.Card()
res = pykms.ResourceManager(card)
conn = res.reserve_connector()
crtc = res.reserve_crtc(conn)
mode = conn.get_default_mode()

planes = []
for p in card.planes:
    if p.supports_crtc(crtc) == False:
        continue
    planes.append(p)

card.disable_planes()

w = mode.hdisplay
h = mode.vdisplay
side = int(h/4)

#print "width = {}, height = {}".format(w,h)

fbs=[]

for i in range(len(planes)):
    fbs.append(pykms.DumbFramebuffer(card, w, h, pykms.PixelFormat.ARGB8888))
    pykms.draw_rect(fbs[i], 0, 0, side, side, pykms.RGB(128, 255*(1 & 2**i), 255*((2 & 2**i) >> i), 255*((4 & 2**i) >> i)))

crtc.set_props({
    "trans-key-mode": 0,
    "trans-key": 0,
    "background": 0,
    "alpha_blender": 1,
})

for i in range(len(planes)):
    plane = planes[i]
    fb = fbs[i]
    print("set crtc {}, plane {}, fb {} ({}, {})".format(crtc.id, plane.id, fbs[i].id, fb.width, fb.height))
    
    plane.set_props({
        "FB_ID": fb.id,
        "CRTC_ID": crtc.id,
        "SRC_W":  side << 16,
        "SRC_H":  side << 16,
        "CRTC_X": i*100,
        "CRTC_Y": i*100,
        "CRTC_W": side,
        "CRTC_H": side,
        "zorder": i,
    })

time.sleep(3)
