#!/usr/bin/env python3
"""Private GLB geometry quality gate for ABVM Grade 2 Mrs. Benulis.

No photo/model is stored, copied, or uploaded by this tool. A structural pass
NEVER means approved likeness, real Roblox render, or public-use permission.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import numpy as np
import trimesh

MAX_BYTES = 18_000_000
MAX_TRIANGLES = 95_000
MAX_MESHES = 95
MAX_TRIANGLES_PER_MESH = 19_500
MAX_TEXTURE_PIXELS = 4096 * 4096
CLOSED_PARTS = (
    ("head", ("head",)),
    ("torso", ("sweater", "torso", "body")),
    ("left_arm", ("left_arm", "l_arm", "l_sleeve")),
    ("right_arm", ("right_arm", "r_arm", "r_sleeve")),
    ("left_hand", ("left_hand", "l_hand", "l_palm")),
    ("right_hand", ("right_hand", "r_hand", "r_palm")),
    ("left_trouser", ("left_trouser", "l_trouser", "l_leg")),
    ("right_trouser", ("right_trouser", "r_trouser", "r_leg")),
    ("left_shoe", ("left_shoe", "l_shoe")),
    ("right_shoe", ("right_shoe", "r_shoe")),
)


def matches_part(mesh_name: str, part: str, aliases: tuple[str, ...]) -> bool:
    slug = mesh_name.lower().replace("-", "_")
    side = "left" if part.startswith("left_") else "right" if part.startswith("right_") else None
    if side:
        wrong = ("r_", "right_") if side == "left" else ("l_", "left_")
        required = ("l_", "left_") if side == "left" else ("r_", "right_")
        if slug.startswith(wrong) or not slug.startswith(required):
            return False
        fallback = (
            ("palm", "finger", "hand") if part.endswith("_hand") else
            ("sleeve", "arm") if part.endswith("_arm") else
            ("leg", "trouser") if part.endswith("_trouser") else
            ("shoe", "flat") if part.endswith("_shoe") else ()
        )
        return any(a in slug for a in aliases) or any(a in slug for a in fallback)
    return any(a in slug for a in aliases)


def inspect(glb: Path) -> dict:
    errors, stats = [], {}
    if not glb.is_file():
        return {"passed": False, "problems": ["GLB_FILE_NOT_FOUND"], "checks": stats}
    if glb.suffix.lower() != ".glb":
        errors.append("NOT_GLTF_BINARY")
    stats["file_bytes"] = glb.stat().st_size
    if stats["file_bytes"] > MAX_BYTES:
        errors.append("OVER_FILE_BUDGET")
    try:
        scene = trimesh.load(glb, force="scene")
    except Exception as e:
        return {"passed": False, "problems": ["GLB_UNREADABLE:" + type(e).__name__], "checks": stats}

    meshes = list(scene.geometry.items())
    count, triangles = len(meshes), sum(len(mesh.faces) for _, mesh in meshes)
    stats.update({"mesh_count": count, "triangles": triangles,
                  "extents_studs": np.round(scene.extents, 4).tolist()})
    if not 8 <= count <= MAX_MESHES:
        errors.append("MESH_COUNT")
    if not 6000 <= triangles <= MAX_TRIANGLES:
        errors.append("TRIANGLE_BUDGET")
    if scene.bounds is None or not np.isfinite(scene.bounds).all():
        errors.append("NONFINITE_BOUNDS")
    else:
        width, height, depth = scene.extents
        if not (5.1 <= height <= 6.8 and 1.1 <= width <= 2.45 and .55 <= depth <= 2.0):
            errors.append("INVALID_FULL_BODY_SCALE")
        if not (-.06 <= scene.bounds[0, 1] <= .12):
            errors.append("FEET_NOT_ON_Y_ZERO")

    found = {part: [] for part, _ in CLOSED_PARTS}
    for name, mesh in meshes:
        for part, aliases in CLOSED_PARTS:
            if matches_part(name, part, aliases):
                found[part].append(name)
        if not np.isfinite(mesh.vertices).all():
            errors.append("NONFINITE_VERTICES:" + name)
        if len(mesh.faces) > MAX_TRIANGLES_PER_MESH:
            errors.append("MESH_TRIANGLE_LIMIT:" + name)
        if not np.isfinite(mesh.area) or mesh.area <= 1e-5:
            errors.append("DEGENERATE_SURFACE:" + name)
        material = getattr(mesh.visual, "material", None)
        image = getattr(material, "baseColorTexture", None)
        if image is not None and image.width * image.height > MAX_TEXTURE_PIXELS:
            errors.append("TEXTURE_SIZE:" + name)

    closed_checks = {}
    for part, aliases in CLOSED_PARTS:
        names = found[part]
        if not names:
            errors.append("MISSING_ANATOMY:" + part)
            continue
        sealed = False
        for name in names:
            mesh = scene.geometry[name].copy()
            # Weld glTF UV seam duplicates before evaluating manifold geometry.
            mesh.merge_vertices(merge_tex=True, merge_norm=True)
            if mesh.is_watertight and mesh.volume > 1e-5:
                sealed = True
                break
        closed_checks[part] = {"candidates": names, "sealed": sealed}
        if not sealed:
            errors.append("OPEN_ANATOMY:" + part)
    stats["closed_anatomy"] = closed_checks
    names = "|".join(scene.geometry).lower()
    if not any(x in names for x in ("eyelid", "iris")):
        errors.append("NO_3D_EYE_GEOMETRY")
    if not any(x in names for x in ("bob", "salon_hair", "hair_lock")):
        errors.append("HAIR_STRUCTURE_MISSING")
    stats["file_sha256"] = hashlib.sha256(glb.read_bytes()).hexdigest()
    stats["release_evidence_required"] = [
        "human acceptance of likeness, hair and anatomy",
        "actual Roblox Studio front/quarter/side/back renders",
        "actual iPhone movement/frame rate and textures",
        "permission for public depiction of recognisable teacher",
        "Roblox creator-owned approved Model asset ID"
    ]
    return {"passed": not errors, "problems": sorted(set(errors)), "checks": stats}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("glb", type=Path)
    parser.add_argument("--report", type=Path)
    args = parser.parse_args()
    result = inspect(args.glb)
    report = json.dumps(result, indent=2, sort_keys=True)
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(report + "\n")
    print(report)
    raise SystemExit(0 if result["passed"] else 1)
