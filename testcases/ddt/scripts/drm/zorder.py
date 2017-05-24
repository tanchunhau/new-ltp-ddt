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
offset = int(h/2**(len(planes)-1))
l_div = len(planes) - 1

#print "width = {}, height = {}".format(w,h)

fbs=[]

for i in range(len(planes)):
    fbs.append(pykms.DumbFramebuffer(card, w, h, pykms.PixelFormat.RGB888))
    pykms.draw_rect(fbs[i], 0, 0, int(w/l_div), int(h/l_div), pykms.RGB(255*(1 & 2**(i%3)), 255*((2 & 2**(i%3)) >> i), 255*((4 & 2**(i%3)) >> i)))

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
        "SRC_W":  int(w/l_div) << 16,
        "SRC_H":  int(h/l_div) << 16,
        "CRTC_X": i*offset,
        "CRTC_Y": i*offset,
        "CRTC_W": int(w/l_div),
        "CRTC_H": int(h/l_div),
        "zorder": i,
    })

time.sleep(3)
