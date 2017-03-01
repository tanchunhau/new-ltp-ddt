#!/usr/bin/python3

import pykms
import time
import sys
import re

from pykms import white, yellow, cyan, green, red, blue, purple

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

fbs=[]

def test_am5_trans_dest():
    fbs.append(pykms.DumbFramebuffer(card, w, h, "XR24"))
    fbs.append(pykms.DumbFramebuffer(card, w, h, "XR24"))

    fb = fbs[0]
    pykms.draw_rect(fb, 0, 0, fb.width, fb.height, purple)
    pykms.draw_rect(fb, 100, 100, 100, 200, green)
    pykms.draw_rect(fb, 300, 100, 100, 200, red)
    pykms.draw_rect(fb, 500, 100, 100, 200, white)

    fb = fbs[1]
    pykms.draw_rect(fb, 0, 0, fb.width, fb.height, cyan)
    pykms.draw_rect(fb, 250, 100, 200, 200, yellow)

    crtc.set_props({
        "trans-key-mode": 1,
        "trans-key": purple.rgb888,
        "background": 0,
        "alpha_blender": 0,
    })

    plane = 0

    for i in range(0,2):
        print("set crtc {}, plane {}, fb {}".format(crtc.id, planes[i].id, fbs[i].id))

        plane = planes[i]
        fb = fbs[i]
        plane.set_props({
            "FB_ID": fb.id,
            "CRTC_ID": crtc.id,
            "SRC_W": fb.width << 16,
            "SRC_H": fb.height << 16,
            "CRTC_W": fb.width,
            "CRTC_H": fb.height,
            "zorder": i,
        })

        time.sleep(1)

def test_am5_trans_src():
    fbs.append(pykms.DumbFramebuffer(card, w, h, "XR24"))
    fbs.append(pykms.DumbFramebuffer(card, w, h, "XR24"))

    fb = fbs[0]
    pykms.draw_rect(fb, 0, 0, fb.width, fb.height, white)
    pykms.draw_rect(fb, 200, 200, 100, 100, red)
    pykms.draw_rect(fb, fb.width - 300, 200, 100, 100, green)

    fb = fbs[1]
    pykms.draw_rect(fb, 0, 0, fb.width, fb.height, cyan)
    pykms.draw_rect(fb, 100, 100, 500, 500, purple)

    crtc.set_props({
        "trans-key-mode": 2,
        "trans-key": purple.rgb888,
        "background": 0,
        "alpha_blender": 0,
    })

    plane = 0

    for i in range(0,2):
        print("set crtc {}, plane {}, fb {}".format(crtc.id, planes[i].id, fbs[i].id))

        plane = planes[i]
        fb = fbs[i]
        plane.set_props({
            "FB_ID": fb.id,
            "CRTC_ID": crtc.id,
            "SRC_W": fb.width << 16,
            "SRC_H": fb.height << 16,
            "CRTC_W": fb.width,
            "CRTC_H": fb.height,
            "zorder": 3 if i == 1 else 0,
        })

        time.sleep(1)

def test_am4_normal_trans_dst():
    fbs.append(pykms.DumbFramebuffer(card, w, h, "XR24"))
    fbs.append(pykms.DumbFramebuffer(card, w * 2 // 3, h, "XR24"))
    fbs.append(pykms.DumbFramebuffer(card, w * 2 // 3, h, "XR24"))

    fb = fbs[0]
    pykms.draw_rect(fb, 0, 0, w, h, purple)
    pykms.draw_rect(fb, 100, 50, 50, 200, green)
    pykms.draw_rect(fb, 200, 50, 50, 200, red)
    pykms.draw_rect(fb, 300, 50, 50, 200, white)

    fb = fbs[1]
    pykms.draw_rect(fb, 0, 0, fb.width, fb.height, blue)

    fb = fbs[2]
    pykms.draw_rect(fb, 0, 0, fb.width, fb.height, cyan)

    crtc.set_props({
        "trans-key-mode": 1,
        "trans-key": purple.rgb888,
        "background": 0,
        "alpha_blender": 0,
    })

    time.sleep(1)

    plane = planes[0]
    fb = fbs[0]
    plane.set_props({
        "FB_ID": fb.id,
        "CRTC_ID": crtc.id,
        "SRC_W": fb.width << 16,
        "SRC_H": fb.height << 16,
        "CRTC_W": w,
        "CRTC_H": h,
    })

    time.sleep(1)

    plane = planes[1]
    fb = fbs[1]
    plane.set_props({
        "FB_ID": fb.id,
        "CRTC_ID": crtc.id,
        "SRC_X": 0 << 16,
        "SRC_Y": 0 << 16,
        "SRC_W": fb.width << 16,
        "SRC_H": fb.height << 16,
        "CRTC_X": 0,
        "CRTC_Y": 0,
        "CRTC_W": fb.width,
        "CRTC_H": fb.height,
    })

    time.sleep(1)

    plane = planes[2]
    fb = fbs[2]
    plane.set_props({
        "FB_ID": fb.id,
        "CRTC_ID": crtc.id,
        "SRC_X": 0 << 16,
        "SRC_Y": 0 << 16,
        "SRC_W": fb.width << 16,
        "SRC_H": fb.height << 16,
        "CRTC_X": w // 3,
        "CRTC_Y": 0,
        "CRTC_W": fb.width,
        "CRTC_H": fb.height,
    })

def test_am4_normal_trans_src():
    fbs.append(pykms.DumbFramebuffer(card, w, h, "XR24"))
    fbs.append(pykms.DumbFramebuffer(card, w // 2, h, "XR24"))
    fbs.append(pykms.DumbFramebuffer(card, w // 2, h, "XR24"))

    fb = fbs[0]
    pykms.draw_rect(fb, 0, 0, w, h, pykms.RGB(128, 255, 255))
    pykms.draw_rect(fb, 200, 100, 50, 200, red)
    pykms.draw_rect(fb, w - 200 - 50, 100, 50, 200, green)

    fb = fbs[1]
    pykms.draw_rect(fb, 0, 0, fb.width, fb.height, blue)
    pykms.draw_rect(fb, 100, 100, fb.width - 200, fb.height - 200, purple)

    fb = fbs[2]
    pykms.draw_rect(fb, 0, 0, fb.width, fb.height, cyan)
    pykms.draw_rect(fb, 100, 100, fb.width - 200, fb.height - 200, purple)

    crtc.set_props({
        "trans-key-mode": 2,
        "trans-key": purple.rgb888,
        "background": 0,
        "alpha_blender": 0,
    })

    time.sleep(1)

    plane = planes[0]
    fb = fbs[0]
    plane.set_props({
        "FB_ID": fb.id,
        "CRTC_ID": crtc.id,
        "SRC_W": fb.width << 16,
        "SRC_H": fb.height << 16,
        "CRTC_W": w,
        "CRTC_H": h,
    })

    time.sleep(1)

    plane = planes[1]
    fb = fbs[1]
    plane.set_props({
        "FB_ID": fb.id,
        "CRTC_ID": crtc.id,
        "SRC_X": 0 << 16,
        "SRC_Y": 0 << 16,
        "SRC_W": fb.width << 16,
        "SRC_H": fb.height << 16,
        "CRTC_X": 0,
        "CRTC_Y": 0,
        "CRTC_W": fb.width,
        "CRTC_H": fb.height,
    })

    time.sleep(1)

    plane = planes[2]
    fb = fbs[2]
    plane.set_props({
        "FB_ID": fb.id,
        "CRTC_ID": crtc.id,
        "SRC_X": 0 << 16,
        "SRC_Y": 0 << 16,
        "SRC_W": fb.width << 16,
        "SRC_H": fb.height << 16,
        "CRTC_X": w - fb.width,
        "CRTC_Y": 0,
        "CRTC_W": fb.width,
        "CRTC_H": fb.height,
    })

def test_am4_alpha_trans_src():
    fbs.append(pykms.DumbFramebuffer(card, w, h, "XR24"))
    fbs.append(pykms.DumbFramebuffer(card, w // 2, h, "XR24"))
    fbs.append(pykms.DumbFramebuffer(card, w // 2, h, "XR24"))

    fb = fbs[0]
    pykms.draw_rect(fb, 0, 0, w, h, purple)
    pykms.draw_rect(fb, 200, 100, 50, 200, red)
    pykms.draw_rect(fb, w - 200 - 50, 100, 50, 200, green)

    fb = fbs[1]
    pykms.draw_rect(fb, 0, 0, fb.width, fb.height, blue)
    pykms.draw_rect(fb, 100, 100, fb.width - 200, fb.height - 200, purple)

    fb = fbs[2]
    pykms.draw_rect(fb, 0, 0, fb.width, fb.height, cyan)
    pykms.draw_rect(fb, 100, 100, fb.width - 200, fb.height - 200, purple)

    crtc.set_props({
        "trans-key-mode": 1,
        "trans-key": purple.rgb888,
        "background": 0,
        "alpha_blender": 1,
    })

    time.sleep(1)

    plane = planes[0]
    fb = fbs[0]
    plane.set_props({
        "FB_ID": fb.id,
        "CRTC_ID": crtc.id,
        "SRC_W": fb.width << 16,
        "SRC_H": fb.height << 16,
        "CRTC_W": w,
        "CRTC_H": h,
    })

    time.sleep(1)

    plane = planes[1]
    fb = fbs[1]
    plane.set_props({
        "FB_ID": fb.id,
        "CRTC_ID": crtc.id,
        "SRC_X": 0 << 16,
        "SRC_Y": 0 << 16,
        "SRC_W": fb.width << 16,
        "SRC_H": fb.height << 16,
        "CRTC_X": 0,
        "CRTC_Y": 0,
        "CRTC_W": fb.width,
        "CRTC_H": fb.height,
    })

    time.sleep(1)

    plane = planes[2]
    fb = fbs[2]
    plane.set_props({
        "FB_ID": fb.id,
        "CRTC_ID": crtc.id,
        "SRC_X": 0 << 16,
        "SRC_Y": 0 << 16,
        "SRC_W": fb.width << 16,
        "SRC_H": fb.height << 16,
        "CRTC_X": w - fb.width,
        "CRTC_Y": 0,
        "CRTC_W": fb.width,
        "CRTC_H": fb.height,
    })


def usage():
  print("Failed: {} <platform i.e dra7xx> <tranparency type: src|dst|alpha_src(am4 only)>".format(sys.argv[0]))
  exit(1)

if len(sys.argv) != 3 : usage()

platform = sys.argv[1]
t_type = sys.argv[2].lower()

if t_type not in ['src', 'dst', 'alpha_src']: usage()

if re.match('dra7.*|am5.*',platform,re.I):
    if t_type == 'dst':
      test_am5_trans_dest()
    elif t_type == 'src':
      test_am5_trans_src()
    else:
      print("Failed transparency type {} not supported for platform".format(t_type, platform))
elif re.match('am4.*',platform,re.I):
    if t_type == 'dst':
      test_am4_normal_trans_dst()
    elif t_type == 'src':
      test_am4_normal_trans_src()
    elif t_type == 'alpha_src':
      test_am4_alpha_trans_src()
    else:
      print("Failed transparency type {} not supported for platform".format(t_type, platform))
else:
    print("Failed: Platform {} not supported".format(platform))

time.sleep(3)
