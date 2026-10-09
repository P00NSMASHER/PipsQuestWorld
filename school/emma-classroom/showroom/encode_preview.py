"""Emit small source-rendered JPEGs so visual QA can read actual pixels
from GitHub's completed workflow logs through the connected repository.
Never prints secrets or children's personal information.
"""
import base64
import io
import sys
from pathlib import Path
from PIL import Image

folder=Path(sys.argv[1])
# Every rendered viewpoint is inspectable in the source-only CI log.
# In particular, source eye-level staff/rear corridor controls used to be
# rendered and pixel-checked but absent from the compact evidence.
# QA-only views: the 16th overhead rug and 17th straight-on bookshelf face
# catch defects missed by the fixed oblique reading-corner screenshots.
# Neither viewpoint is a Roblox gameplay camera or native iPhone evidence.
names=("01-isometric","02-front","03-top","04-exterior-control",
       "05-eye-front","06-eye-back","07-eye-windows","08-eye-storage",
       "09-chair-back","10-desk-side","11-storage-close-up",
       "12-reading-rug","13-reading-books",
       "14-eye-staff-door","15-eye-rear-corridor",
       "16-rug-overlook","17-library-cover-fronts",
       "18-window-foliage-close")
assert len(names)==18 and len(set(names))==18
print("VISUAL_EVIDENCE_INVENTORY_PASS frames="+str(len(names)),flush=True)
for n in names:
    path=folder/(n+".png")
    if not path.is_file():
        raise FileNotFoundError(path)
    im=Image.open(path).convert("RGB")
    im.thumbnail((960,720))
    b=io.BytesIO()
    im.save(b,format="JPEG",quality=67,optimize=True)
    data=b.getvalue()
    assert 1000<len(data)<350000, "Preview did not contain a bounded actual image"
    print("ABVM_VISUAL_IMAGE_"+n.replace("-","_")+"="+base64.b64encode(data).decode("ascii"),flush=True)
    print("ABVM_VISUAL_INFO_"+n.replace("-","_")+"="+str(im.size)+" jpeg_bytes="+str(len(data)),flush=True)
