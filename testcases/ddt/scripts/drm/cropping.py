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
offset = int(h/4)

#print "width = {}, height = {}".format(w,h)

fbs=[]

for i in range(len(planes)):
    fbs.append(pykms.DumbFramebuffer(card, w, h, pykms.PixelFormat.RGB888))
    pykms.draw_rect(fbs[i], 0, 0, w, h, pykms.RGB(255*(i==0), 255*(i==1), 255*(i==2)))
    pykms.draw_rect(fbs[i], i*offset, i*offset, int(w/2**(i+1)), int(h/2**(i+1)), pykms.RGB(255*(i!=1), 255*(i!=2), 255*(i!=0)))

crtc.set_props({
    "trans-key-mode": 0,
    "trans-key": 0,
    "background": 0,
    "alpha_blender": 1,
})

#Show the whole frame
for i in range(len(planes)):
    plane = planes[i]
    fb = fbs[i]

    print("set crtc {}, plane {}, fb {} ({}, {})".format(crtc.id, plane.id, fbs[i].id, fb.width, fb.height))

    plane.set_props({
        "FB_ID": fb.id,
        "CRTC_ID": crtc.id,
        "SRC_X": 0,
        "SRC_Y": 0,
        "SRC_W": fb.width << 16,
        "SRC_H": fb.height << 16,
        "CRTC_X": 0,
        "CRTC_Y": 0,
        "CRTC_W": fb.width,
        "CRTC_H": fb.height,
        "zorder": i,
    })
    time.sleep(1)

#Show only the cropped rect
for i in range(len(planes)):
    plane = planes[i]
    fb = fbs[i]
    p_w = int(fb.width/2**(i+1))
    p_h = int(fb.height/2**(i+1))
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
