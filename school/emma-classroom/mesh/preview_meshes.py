#!/usr/bin/env python3
"""Orthographic previews built from the generated GLB geometry; no mockups."""
from pathlib import Path
import argparse
import base64
import io
import numpy as np
import trimesh
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d.art3d import Poly3DCollection

PALETTE = {
    "continuous_molded_seat":(.27,.43,.61),
    "single_contoured_school_backrest":(.28,.44,.61),
    "steel_chair_frame":(.68,.7,.72),
    "chair_floor_glides":(.22,.26,.28),
    "one_piece_rounded_laminate_top":(.76,.66,.49),
    "thin_continuous_edge_band":(.46,.46,.45),
    "desk_steel_frames":(.66,.69,.7),
    "open_wire_book_basket":(.55,.60,.63),
    "desk_rubber_feet":(.22,.26,.28)
}

def render(output:Path):
    fig=plt.figure(figsize=(12,8),facecolor="#f8f8f7")
    for index,(name,elev,az,title) in enumerate([
        ("abvm_student_chair",18,-67,"CHAIR  /  DIAGONAL"),
        ("abvm_student_chair",15,0,"CHAIR  /  SIDE"),
        ("abvm_student_desk",22,-57,"DESK  /  DIAGONAL"),
        ("abvm_student_desk",9,-14,"DESK  /  SIDE"),
    ]):
        scene=trimesh.load(str(output/(name+".glb")),force="scene")
        ax=fig.add_subplot(2,2,index+1,projection="3d")
        for key,mesh in scene.geometry.items():
            v=mesh.vertices[:,[0,2,1]]
            tris=v[mesh.faces]
            face=np.cross(tris[:,1]-tris[:,0],tris[:,2]-tris[:,0])
            normal=face/np.maximum(np.linalg.norm(face,axis=1)[:,None],1e-7)
            light=.58+.42*np.maximum(0,normal@np.array([-.4,-.48,.78]))
            col=np.clip(np.asarray(PALETTE.get(key,(.6,.6,.6)))[None,:]*light[:,None],0,1)
            ax.add_collection3d(Poly3DCollection(tris,facecolors=col,edgecolors="none"))
        bbox=scene.bounds[:,[0,2,1]]
        center=bbox.mean(axis=0); radius=max(bbox[1]-bbox[0])/2
        ax.set(xlim=(center[0]-radius*1.3,center[0]+radius*1.3),
               ylim=(center[1]-radius*1.3,center[1]+radius*1.3),
               zlim=(0,max(4.5,center[2]+radius*1.2)))
        ax.set_box_aspect((1,1,1))
        ax.view_init(elev=elev,azim=az)
        ax.set_axis_off()
        ax.set_title(title,fontsize=12)
    fig.suptitle("ABVM original classroom furniture / GLB geometry study",fontsize=17)
    fig.savefig(output/"furniture-mesh-preview.png",dpi=125,facecolor=fig.get_facecolor())
    plt.close(fig)
    # Emit bounded image pixels through GitHub Actions for independent review.
    from PIL import Image
    with Image.open(output/"furniture-mesh-preview.png") as original:
        original.thumbnail((960,720))
        buf=io.BytesIO()
        original.convert("RGB").save(buf,format="JPEG",quality=63,optimize=True)
        print("ABVM_FURNITURE_MODEL_IMAGE="+base64.b64encode(buf.getvalue()).decode(),flush=True)
    print("FURNITURE_MESH_PREVIEW_OK",output/"furniture-mesh-preview.png")

if __name__=="__main__":
    parser=argparse.ArgumentParser()
    parser.add_argument("--dir",type=Path,required=True)
    args=parser.parse_args()
    render(args.dir)
