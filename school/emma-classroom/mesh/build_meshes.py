#!/usr/bin/env python3
"""Original low-poly classroom furniture. No imported models or paid assets.

Exports two GLBs in Roblox-stud scale (Y up). Files are import candidates,
not Roblox asset IDs until Open Cloud acknowledges their import/moderation.
"""
from pathlib import Path
import argparse
import hashlib
import json
import math

import numpy as np
import trimesh
from trimesh.visual.material import PBRMaterial

COLORS = {
    "chair_polymer": [63, 100, 140, 255],
    "steel": [150, 157, 160, 255],
    "rubber": [47, 54, 58, 255],
    "desk_laminate": [193, 170, 131, 255],
    "desk_edge": [117, 118, 114, 255],
    "desk_tray": [111, 127, 134, 255],
}


def colored(mesh, name):
    mesh.visual = trimesh.visual.TextureVisuals(
        material=PBRMaterial(
            baseColorFactor=np.array(COLORS[name]) / 255.0,
            metallicFactor=.45 if name in ("steel", "desk_tray") else 0,
            roughnessFactor=.55 if name in ("steel", "desk_tray") else .76,
        )
    )
    return mesh


def panel(name, plane, center, a, b, thick, exponent, taper=0, bend=0, sides=48, rings=5):
    """Continuous sealed beveled superellipse. Not a stack of rounded Blocks."""
    points = []
    tris = []
    for face in (0, 1):
        for radial in range(rings):
            t = radial / (rings - 1)
            for k in range(sides):
                angle = 2 * math.pi * k / sides
                cx, cy = math.cos(angle), math.sin(angle)
                u = math.copysign(abs(cx) ** (2 / exponent), cx) * a * t
                v = math.copysign(abs(cy) ** (2 / exponent), cy) * b * t
                if plane == "XY":
                    u *= 1 - taper * ((v + b) / (2 * b) - .5)
                    z = center[2] + (thick / 2 if face == 0 else -thick / 2)
                    z += bend * (u / a) ** 2 + .038 * (v / b) ** 2
                    points.append((center[0] + u, center[1] + v, z))
                else:
                    y = center[1] + (thick / 2 if face == 0 else -thick / 2)
                    points.append((center[0] + u, y, center[2] + v))
    for face in (0, 1):
        offset = face * rings * sides
        for ring in range(rings - 1):
            for i in range(sides):
                p = offset + ring * sides + i
                q = offset + ring * sides + (i + 1) % sides
                r = offset + (ring + 1) * sides + i
                s = offset + (ring + 1) * sides + (i + 1) % sides
                tris.extend(((p, q, s), (p, s, r)) if face == 0 else ((p, s, q), (p, r, s)))
    outer = (rings - 1) * sides
    opposite = rings * sides + outer
    for i in range(sides):
        a0, b0 = outer + i, outer + (i + 1) % sides
        a1, b1 = opposite + i, opposite + (i + 1) % sides
        tris.extend(((a0, a1, b1), (a0, b1, b0)))
    result = trimesh.Trimesh(vertices=np.asarray(points), faces=np.asarray(tris), process=True)
    result.fix_normals()
    return colored(result, name)


def rod(a, b, radius=.085, sides=10):
    start, finish = np.asarray(a, float), np.asarray(b, float)
    delta = finish - start
    mesh = trimesh.creation.cylinder(radius=radius, height=np.linalg.norm(delta), sections=sides)
    mesh.apply_transform(trimesh.geometry.align_vectors([0, 0, 1], delta / np.linalg.norm(delta)))
    mesh.apply_translation((start + finish) / 2)
    return mesh


def joined(parts, color):
    return colored(trimesh.util.concatenate(parts), color)


def chair():
    scene = trimesh.Scene()
    scene.add_geometry(panel("chair_polymer", "XZ", (0, 1.62, 0), 1.23, 1.04, .23, 5.2),
                       geom_name="continuous_molded_seat")
    back = panel("chair_polymer", "XY", (0, 2.91, 1.02), 1.20, .94, .19, 4.8,
                 taper=.11, bend=.085)
    back.apply_transform(trimesh.transformations.rotation_matrix(
        math.radians(-8), [1, 0, 0], point=[0, 2.91, 1.02]))
    scene.add_geometry(back, geom_name="single_contoured_school_backrest")
    steel, feet = [], []
    for x in (-.84, .84):
        for z in (-.69, .69):
            steel.append(rod((x, .18, z), (x, 1.53, z), .076))
            feet.append(rod((x, .085, z), (x, .23, z), .108, 12))
        steel.extend([
            rod((x, 1.43, -.73), (x, 1.43, .96), .078),
            rod((x, 1.55, .83), (x, 3.07, 1.08), .073),
            rod((x, 2.63, 1.02), (x * .95, 3.25, 1.10), .062),
        ])
    steel.append(rod((-.84, 1.35, -.59), (.84, 1.35, -.59), .063))
    scene.add_geometry(joined(steel, "steel"), geom_name="steel_chair_frame")
    scene.add_geometry(joined(feet, "rubber"), geom_name="chair_floor_glides")
    return scene


def desk():
    scene = trimesh.Scene()
    scene.add_geometry(panel("desk_laminate", "XZ", (0, 3.105, 0), 2.86, 1.90, .12, 9),
                       geom_name="one_piece_rounded_laminate_top")
    scene.add_geometry(panel("desk_edge", "XZ", (0, 2.995, 0), 2.89, 1.93, .09, 9,
                             rings=3), geom_name="thin_continuous_edge_band")
    steel, feet, tray = [], [], []
    for x in (-2.20, 2.20):
        for z in (-1.32, 1.32):
            steel.append(rod((x, .19, z), (x, 2.92, z), .086))
            feet.append(rod((x, .08, z), (x, .21, z), .12, 12))
        steel.append(rod((x, .27, -1.53), (x, .27, 1.53), .088))
        steel.append(rod((x, 2.55, -1.3), (x, 2.55, 1.3), .065))
    for z in (-1.23, 1.23):
        steel.append(rod((-2.2, 2.64, z), (2.2, 2.64, z), .074))
    for x in np.linspace(-2.17, 2.17, 10):
        tray.append(rod((x, 2.29, -1.25), (x, 2.29, 1.25), .032, 8))
    for z in (-1.25, 1.25):
        tray.append(rod((-2.23, 2.29, z), (2.23, 2.29, z), .054))
    scene.add_geometry(joined(steel, "steel"), geom_name="desk_steel_frames")
    scene.add_geometry(joined(tray, "desk_tray"), geom_name="open_wire_book_basket")
    scene.add_geometry(joined(feet, "rubber"), geom_name="desk_rubber_feet")
    return scene


def build(output):
    output.mkdir(parents=True, exist_ok=True)
    models = []
    for name, fn in (("abvm_student_chair", chair), ("abvm_student_desk", desk)):
        scene = fn()
        path = output / (name + ".glb")
        path.write_bytes(scene.export(file_type="glb"))
        imported = trimesh.load(str(path), force="scene")
        assert len(imported.geometry) >= 3
        assert np.isfinite(imported.bounds).all()
        assert .1 < imported.extents.min() and imported.extents.max() < 7
        assert sum(len(g.faces) for g in imported.geometry.values()) < 4000
        models.append({
            "name": name,
            "file": path.name,
            "triangles": sum(len(g.faces) for g in imported.geometry.values()),
            "size_studs": np.around(imported.extents, 3).tolist(),
            "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
        })
        print("MESH_VALID", name, models[-1])
    (output / "manifest.json").write_text(json.dumps(
        {"units": "Roblox studs, Y up, relative to classroom floor",
         "new_assets_not_published": True,
         "models": models}, indent=2))
    return models


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    build(args.out)
