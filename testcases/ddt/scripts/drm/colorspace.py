#!/usr/bin/python3

import pykms
import time

card = pykms.Card()
res = pykms.ResourceManager(card)
conn = res.reserve_connector("")
crtc = res.reserve_crtc(conn)
mode = conn.get_default_mode()
modeb = mode.to_blob(card)
plane = res.reserve_generic_plane(crtc, pykms.PixelFormat.UYVY)

fb = pykms.DumbFramebuffer(card, mode.hdisplay, mode.vdisplay, "UYVY");
pykms.draw_test_pattern(fb);

req = pykms.AtomicReq(card)
req.add(conn, "CRTC_ID", crtc.id)
req.add(crtc, {"ACTIVE": 1,
               "MODE_ID": modeb.id})

r = req.commit_sync(allow_modeset = True)

req = pykms.AtomicReq(card)
req.add(plane, {
	"FB_ID": fb.id,
	"CRTC_ID": crtc.id,
	"SRC_X": 0,
	"SRC_Y": 0,
	"SRC_W":  mode.hdisplay << 16,
	"SRC_H":  mode.vdisplay << 16,
	"CRTC_X": 0,
	"CRTC_Y": 0,
	"CRTC_W": mode.hdisplay,
	"CRTC_H": mode.vdisplay,
	})
r = req.commit_sync()

yuv_types = {(0, 0) : pykms.YUVType.BT601_Lim,
             (0, 1) : pykms.YUVType.BT601_Full,
             (1, 0) : pykms.YUVType.BT709_Lim,
             (1, 1) : pykms.YUVType.BT709_Full}

encoding_enums = plane.get_prop("COLOR_ENCODING").enums
range_enums = plane.get_prop("COLOR_RANGE").enums

for encoding in encoding_enums:
    for yuv_range in range_enums:
        print(yuv_types[(encoding, yuv_range)])
        req = pykms.AtomicReq(card)
        req.add(plane, {"COLOR_ENCODING": encoding,
                 "COLOR_RANGE": yuv_range})
        req.commit_sync()
        pykms.draw_test_pattern(fb, yuv_types[(encoding, yuv_range)]);
        time.sleep(1)
