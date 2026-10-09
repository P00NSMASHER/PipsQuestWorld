#!/usr/bin/env python3
"""Check foliage visibility in the fixed source-rendered 07 window camera.
This is not native Roblox/iPhone acceptance; never use on arbitrary views.
"""
from PIL import Image,ImageDraw
from pathlib import Path
import sys

AREAS={"left":(.398,.420,.515,.553),"right":(.599,.420,.720,.553)}
SIZE=(960,540)

def measure(image):
    im=image.convert("RGB").resize(SIZE)
    result={}
    for name,(a,b,c,d) in AREAS.items():
        crop=im.crop((round(a*960),round(b*540),round(c*960),round(d*540)))
        coords=[]
        for n,(r,g,blue) in enumerate(crop.getdata()):
            if 48<=g<=205 and g>=r*1.08 and g>=blue*1.02 and g-r>=9 and g-blue>=3:
                coords.append((n%crop.width,n//crop.width))
        span_x=max((p[0] for p in coords),default=0)-min((p[0] for p in coords),default=0)
        span_y=max((p[1] for p in coords),default=0)-min((p[1] for p in coords),default=0)
        result[name]=(len(coords),span_x,span_y)
    return result

def valid(stats):
    return all(n>=45 and w>=10 and h>=8 for n,w,h in stats.values())

def self_test():
    blank=Image.new("RGB",SIZE,(205,213,221))
    assert not valid(measure(blank))
    good=blank.copy(); d=ImageDraw.Draw(good)
    for x,y,_,_ in AREAS.values():
        x,y=round(x*960),round(y*540)
        d.ellipse((x+15,y+14,x+49,y+44),fill=(99,145,116))
    assert valid(measure(good)), "Two populated windows should pass"
    one=blank.copy();d=ImageDraw.Draw(one)
    d.ellipse((395,246,426,276),fill=(99,145,116))
    assert not valid(measure(one)), "Only one window must fail"
    small=blank.copy();d=ImageDraw.Draw(small)
    for x,y,_,_ in AREAS.values():
        x,y=round(x*960),round(y*540)
        d.rectangle((x+20,y+20,x+22,y+22),fill=(99,145,116))
    assert not valid(measure(small)), "Tiny green dots must fail"
    outside=blank.copy()
    ImageDraw.Draw(outside).rectangle((20,20,170,130),fill=(99,145,116))
    assert not valid(measure(outside)), "Outside greenery must fail"
    print("SOURCE_WINDOW_FOLIAGE_SELF_TEST_PASS blank_rejected=true one_window_rejected=true dots_rejected=true external_green_rejected=true")

if __name__=="__main__":
    if len(sys.argv)==2 and sys.argv[1]=="--self-test":
        self_test()
    elif len(sys.argv)==2:
        path=Path(sys.argv[1])
        if not path.is_file(): raise SystemExit("SOURCE_WINDOW_FOLIAGE_REJECT no screenshot")
        with Image.open(path) as im: result=measure(im)
        if not valid(result): raise SystemExit("SOURCE_WINDOW_FOLIAGE_REJECT "+str(result))
        print("SOURCE_WINDOW_FOLIAGE_PASS two_windows=true left_pixels="+str(result["left"][0])+" right_pixels="+str(result["right"][0])+" native_iphone_pending=true")
    else:
        raise SystemExit("Usage: check_window_foliage.py <07-eye-windows.png> | --self-test")
