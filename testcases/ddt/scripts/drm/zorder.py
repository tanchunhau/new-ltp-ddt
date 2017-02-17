#!/usr/bin/python

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
offset = int(h/4)

#print "width = {}, height = {}".format(w,h)

fbs=[]

for i in range(len(planes)):
    fbs.append(pykms.DumbFramebuffer(card, w, h, pykms.PixelFormat.RGB888))
    pykms.draw_rect(fbs[i], 0, 0, w/2, h/2, pykms.RGB(255*(1 & 2**i), 255*((2 & 2**i) >> i), 255*((4 & 2**i) >> i)))

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
        "SRC_X": 0,
        "SRC_Y": 0,
        "SRC_W":  w/2 << 16,
        "SRC_H":  h/2 << 16,
        "CRTC_X": i*offset,
        "CRTC_Y": i*offset,
        "CRTC_W": w/2,
        "CRTC_H": h/2,
        "zorder": i,
    })

time.sleep(3)
