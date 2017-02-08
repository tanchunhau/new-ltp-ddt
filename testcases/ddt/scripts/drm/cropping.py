#!/usr/bin/python

import pykms
import time
import random

# This hack makes drm initialize the fbcon, setting up the default connector
card = pykms.Card()
card = 0

card = pykms.OmapCard()
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
    fbs.append(pykms.OmapFramebuffer(card, w, h, pykms.PixelFormat.ARGB8888))
    pykms.draw_rect(fbs[i], i*offset, i*offset, w/2, h/2, pykms.RGB(128, 255*(1 & 2**i), 255*((2 & 2**i) >> i), 255*((4 & 2**i) >> i)))

crtc.set_props({
    "trans-key-mode": 0,
    "trans-key": 0,
    "background": 0,
    "alpha_blender": 1,
})

for i in range(len(planes)):
    plane = planes[i]
    fb = fbs[i]
    p_w = fb.width/2**(i+1)
    p_h = fb.height/2**(i+1)
    print("set crtc {}, plane {}, fb {} ({}, {})".format(crtc.id, plane.id, fbs[i].id, fb.width, fb.height))
    
    plane.set_props({
        "FB_ID": fb.id,
        "CRTC_ID": crtc.id,
        "SRC_X": i*offset << 16,
        "SRC_Y": i*offset << 16,
        "SRC_W":  p_w << 16,
        "SRC_H":  p_h << 16,
        "CRTC_X": 0,
        "CRTC_Y": 0,
        "CRTC_W": p_w,
        "CRTC_H": p_h,
        "zorder": i,
    })

time.sleep(3)
