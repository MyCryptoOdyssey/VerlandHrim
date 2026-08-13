#!/usr/bin/env python3
"""rgba_png.py - convert GemForge .rgba (+.json) <-> PNG for AC PFID_A8R8G8B8 icons.
AC stores each pixel as a little-endian int32 ARGB => bytes on disk are B,G,R,A.
usage:
  python rgba_png.py topng  <base>            # base.rgba + base.json -> base.png
  python rgba_png.py torgba <in.png> <base>   # png -> base.rgba (+ base.json w/ dims)
  python rgba_png.py recolor <base> <outdir> <name:hex> [name:hex ...]
     hue-replace: shifts the gem's hue toward each target hex, keeps shading/alpha
"""
import sys, json, colorsys
from PIL import Image

def topng(base):
    meta = json.load(open(base + ".json"))
    w, h = meta["Width"], meta["Height"]
    raw = open(base + ".rgba", "rb").read()
    img = Image.new("RGBA", (w, h))
    px = img.load()
    for i in range(w * h):
        b, g, r, a = raw[i*4], raw[i*4+1], raw[i*4+2], raw[i*4+3]
        px[i % w, i // w] = (r, g, b, a)
    img.save(base + ".png")
    print(f"OK {base}.png {w}x{h}")

def torgba(png, base, meta_from=None):
    img = Image.open(png).convert("RGBA")
    w, h = img.size
    out = bytearray()
    for y in range(h):
        for x in range(w):
            r, g, b, a = img.getpixel((x, y))
            out += bytes((b, g, r, a))
    open(base + ".rgba", "wb").write(out)
    meta = json.load(open(meta_from)) if meta_from else {}
    meta.update({"Width": w, "Height": h, "FormatValue": 21, "Format": "PFID_A8R8G8B8", "Bytes": len(out)})
    json.dump(meta, open(base + ".json", "w"), indent=2)
    print(f"OK {base}.rgba {w}x{h} ({len(out)} bytes)")

def recolor(base, outdir, specs):
    import os
    os.makedirs(outdir, exist_ok=True)
    img = Image.open(base + ".png").convert("RGBA")
    w, h = img.size
    for spec in specs:
        name, hexv = spec.split(":")
        hexv = hexv.lstrip("#")
        tr, tg, tb = int(hexv[0:2],16), int(hexv[2:4],16), int(hexv[4:6],16)
        th, ts, tv = colorsys.rgb_to_hsv(tr/255, tg/255, tb/255)
        out = Image.new("RGBA", (w, h))
        for y in range(h):
            for x in range(w):
                r, g, b, a = img.getpixel((x, y))
                hh, ss, vv = colorsys.rgb_to_hsv(r/255, g/255, b/255)
                # keep the pixel's brightness curve; adopt target hue; blend saturation
                if ss > 0.08:   # colored pixel -> re-hue
                    nr, ng, nb = colorsys.hsv_to_rgb(th, max(ts*0.85, ss*0.6), vv)
                else:           # near-gray (outline/spark) -> leave alone
                    nr, ng, nb = r/255, g/255, b/255
                out.putpixel((x, y), (int(nr*255), int(ng*255), int(nb*255), a))
        p = f"{outdir}/{name}.png"
        out.save(p)
        print(f"OK {p} <- #{hexv}")

cmd = sys.argv[1]
if cmd == "topng": topng(sys.argv[2])
elif cmd == "torgba": torgba(sys.argv[2], sys.argv[3], sys.argv[4] if len(sys.argv)>4 else None)
elif cmd == "recolor": recolor(sys.argv[2], sys.argv[3], sys.argv[4:])
