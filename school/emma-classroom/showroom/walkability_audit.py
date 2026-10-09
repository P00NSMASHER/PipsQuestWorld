#!/usr/bin/env python3
"""Source-derived, conservative player-footprint navigation audit.

The real showroom Luau constructors run with the same geometry doubles as
the renderer. This is NOT Roblox physics, a native camera render, or a phone
test. We inspect CanCollide and transforms, conservatively project rotated
part bounds onto the floor, and require a connected route from the spawn to
all major parts of the classroom. Static floors and overhead fixtures do not
obstruct a standing avatar.

Do not lower clearance thresholds or substitute cutaway scene geometry to
manufacture a pass. A red result requires inspection of the named blockers.
"""
from __future__ import annotations

import argparse
from collections import deque
from dataclasses import dataclass
import json
import math
from pathlib import Path
import subprocess
import tempfile

from export_source_scene import generate_luau

STEP = 0.75
AVATAR_RADIUS = 1.0  # Conservative nominal Roblox character footprint.
BODY_BOTTOM = 0.85
BODY_TOP = 5.75
X_MIN, X_MAX = -35.0, 54.0
Z_MIN, Z_MAX = -32.0, 48.0
START = (5.0, 24.0)
GOALS = {
    "front_teaching_wall": (5.0, -24.0),
    "rear_entry_hallway": (0.0, 36.0),
    "window_wall": (-32.0, 1.0),
    "reading_corner_approach": (-29.0, -23.0),
    "right_side_aisle": (28.0, -11.0),
    "side_staff_hallway": (44.0, 15.5),
}

# Extra Luau probe is appended to the *actual* constructor snapshot. The
# renderer's 24-field PART output remains unchanged and never loses walls.
NAV_PROBE = r'''
local count=0
for _,p in ipairs(Room.Root:GetDescendants()) do
    if p:IsA("BasePart") and p.CanCollide == true then
        local cf=p.CFrame
        local m=cf.m
        local size=p.Size
        local pos=cf.Position
        local name=string.gsub(tostring(p.Name),"[|\r\n]"," ")
        local fields={
            "NAV",name,
            string.format("%.6f",size.X),
            string.format("%.6f",size.Y),
            string.format("%.6f",size.Z),
            string.format("%.6f",pos.X),
            string.format("%.6f",pos.Y),
            string.format("%.6f",pos.Z),
        }
        for i=1,9 do fields[#fields+1]=string.format("%.6f",m[i]) end
        print(table.concat(fields,"|"))
        count+=1
    end
end
print("NAV_COUNT|"..count)
'''

@dataclass(frozen=True)
class Blocker:
    name: str
    xmin: float
    xmax: float
    zmin: float
    zmax: float

    def covers(self, x: float, z: float) -> bool:
        return self.xmin <= x <= self.xmax and self.zmin <= z <= self.zmax


def as_blockers(rows: list[list[str]]) -> list[Blocker]:
    result = []
    for row in rows:
        assert len(row) == 17, "Malformed 3D collision evidence"
        _, name, *values = row
        sx, sy, sz, px, py, pz, *m = map(float, values)
        assert all(math.isfinite(v) for v in values_as_float(values)), name
        assert sx > 0 and sy > 0 and sz > 0, name
        # Project the rotated 3D box onto each world axis. This slightly
        # overestimates angled objects and errs towards flagging obstructions.
        rx = (abs(m[0])*sx + abs(m[1])*sy + abs(m[2])*sz)/2
        ry = (abs(m[3])*sx + abs(m[4])*sy + abs(m[5])*sz)/2
        rz = (abs(m[6])*sx + abs(m[7])*sy + abs(m[8])*sz)/2
        if py+ry <= BODY_BOTTOM or py-ry >= BODY_TOP:
            continue
        result.append(Blocker(name, px-rx-AVATAR_RADIUS, px+rx+AVATAR_RADIUS,
                              pz-rz-AVATAR_RADIUS, pz+rz+AVATAR_RADIUS))
    return result


def values_as_float(values: list[str]):
    for value in values:
        yield float(value)


class Grid:
    def __init__(self, blockers: list[Blocker]):
        self.w = int(math.floor((X_MAX-X_MIN)/STEP))+1
        self.h = int(math.floor((Z_MAX-Z_MIN)/STEP))+1
        self.blocked: set[tuple[int,int]] = set()
        for b in blockers:
            xa = max(0, math.ceil((b.xmin-X_MIN)/STEP))
            xb = min(self.w-1, math.floor((b.xmax-X_MIN)/STEP))
            za = max(0, math.ceil((b.zmin-Z_MIN)/STEP))
            zb = min(self.h-1, math.floor((b.zmax-Z_MIN)/STEP))
            for x in range(xa,xb+1):
                for z in range(za,zb+1):
                    self.blocked.add((x,z))

    def xy(self, point: tuple[float,float]) -> tuple[int,int]:
        x,z = point
        cell = (round((x-X_MIN)/STEP), round((z-Z_MIN)/STEP))
        assert 0 <= cell[0] < self.w and 0 <= cell[1] < self.h, "Checkpoint outside grid"
        return cell

    def pos(self, cell: tuple[int,int]) -> tuple[float,float]:
        return (round(X_MIN+cell[0]*STEP,2), round(Z_MIN+cell[1]*STEP,2))

    def connected(self, start: tuple[float,float]) -> tuple[dict,dict]:
        s = self.xy(start)
        assert s not in self.blocked, "Spawn lies inside a collidable obstruction"
        queue=deque([s])
        distance={s:0}
        previous={}
        while queue:
            x,z = queue.popleft()
            for other in ((x-1,z),(x+1,z),(x,z-1),(x,z+1)):
                a,b = other
                if (a<0 or b<0 or a>=self.w or b>=self.h
                    or other in self.blocked or other in distance):
                    continue
                distance[other] = distance[(x,z)]+1
                previous[other] = (x,z)
                queue.append(other)
        return distance, previous

    def closest_reachable(self, target: tuple[float,float],
                          distance: dict, radius: float = 1.5):
        tx,tz = target
        matches = []
        for cell,steps in distance.items():
            x,z=self.pos(cell)
            d=math.hypot(x-tx,z-tz)
            if d <= radius:
                matches.append((steps,d,cell))
        if not matches:
            return None
        _,_,choice=min(matches)
        return choice


def inspect(blockers: list[Blocker]) -> dict:
    assert blockers, "No physical colliders exported; source probe is not valid"
    grid=Grid(blockers)
    try:
        distance,previous=grid.connected(START)
    except AssertionError:
        hits=[b.name for b in blockers if b.covers(*START)]
        raise AssertionError("BLOCKED_SPAWN sources="+", ".join(sorted(set(hits))[:12]))
    routes={}
    failures=[]
    for label,point in GOALS.items():
        cell=grid.closest_reachable(point,distance)
        if cell is None:
            hits=[b.name for b in blockers if b.covers(*point)]
            failures.append(f"{label}@{point}: nearby={sorted(set(hits))[:8]}")
            continue
        nodes=[]
        cursor=cell
        while True:
            nodes.append(list(grid.pos(cursor)))
            if cursor==grid.xy(START):
                break
            cursor=previous[cursor]
        nodes.reverse()
        routes[label] = {
            "length_studs":round(distance[cell]*STEP,2),
            "endpoint":nodes[-1],
            "waypoints":nodes,
        }
    if failures:
        raise AssertionError("BLOCKED_NAVIGATION "+ " | ".join(failures))
    assert len(routes)==len(GOALS), "Incomplete route acceptance"
    return {
        "mode":"source-derived static approximate footprints; not native Roblox physics",
        "grid_studs":STEP,
        "avatar_radius_studs":AVATAR_RADIUS,
        "reachable_cells":len(distance),
        "blockers":len(blockers),
        "start":list(START),
        "routes":routes,
    }


def assert_no_mobile_stand_colliders(rows: list[list[str]]) -> None:
    offenders=sorted({row[1] for row in rows
                      if len(row)>1 and row[1].startswith("Mobile smartboard ")})
    assert not offenders, (
        "Photo-only Smartboard stand must remain noncolliding: "
        + ", ".join(offenders)
    )


def assert_no_window_drapery_colliders(rows: list[list[str]]) -> None:
    offenders=sorted({row[1] for row in rows
                      if len(row)>1 and (
                          row[1].startswith("Navy curtain ")
                          or row[1]=="Blue curtain valance"
                      )})
    assert not offenders, (
        "Photo-only school window drapes must remain noncolliding: "
        + ", ".join(offenders)
    )


def get_source_blockers(luau: str) -> list[Blocker]:
    with tempfile.TemporaryDirectory(prefix="abvm-nav-") as folder:
        path=Path(folder)/"room.lua"
        path.write_text(generate_luau()+"\n"+NAV_PROBE,encoding="utf-8")
        proc=subprocess.run([luau,str(path)],capture_output=True,text=True,timeout=115)
    if proc.returncode:
        raise RuntimeError("Actual Luau classroom construction failed: "+
                           proc.stderr[-3000:]+" "+proc.stdout[-1200:])
    rows=[line.split("|") for line in proc.stdout.splitlines() if line.startswith("NAV|")]
    counts=[line for line in proc.stdout.splitlines() if line.startswith("NAV_COUNT|")]
    assert counts and len(rows)==int(counts[-1].split("|")[1]), (
        "Collision probe lost rows or construction never completed"
    )
    assert 50 < len(rows) < 2000, "Unexpected collider count: "+str(len(rows))
    # Source construction must never promote photo-only wheeled stand parts
    # into physical walkway colliders, even when six broad routes still pass.
    assert_no_mobile_stand_colliders(rows)
    assert_no_window_drapery_colliders(rows)
    return as_blockers(rows)


def self_test():
    # A floor below the character cannot close a corridor.
    flat=["NAV","floor","20","1","20","0","0","0",
          "1","0","0","0","1","0","0","0","1"]
    assert not as_blockers([flat])
    # A rotated vertical wall must still block the walkable height.
    tall=["NAV","wall","1","7","8","5","3","24",
          "1","0","0","0","1","0","0","0","1"]
    pieces=as_blockers([tall])
    assert len(pieces)==1 and pieces[0].covers(5,24)
    try:
        inspect(pieces)
        raise AssertionError("Blocked spawn test was accepted")
    except AssertionError as e:
        assert "BLOCKED_SPAWN" in str(e)
    assert Grid([]).connected(START)[0], "Empty room must remain traversable"
    assert_no_mobile_stand_colliders([flat,tall])
    try:
        assert_no_mobile_stand_colliders([
            ["NAV","Mobile smartboard caster",*flat[2:]]
        ])
        raise AssertionError("Colliding rolling Smartboard test was accepted")
    except AssertionError as e:
        assert "noncolliding" in str(e)
    assert_no_window_drapery_colliders([flat,tall])
    try:
        assert_no_window_drapery_colliders([
            ["NAV","Navy curtain fabric panel",*flat[2:]]
        ])
        raise AssertionError("Colliding drapery self-test was accepted")
    except AssertionError as e:
        assert "noncolliding" in str(e)
    print("STATIC_NAV_SELF_TEST_PASS (floor ignored, blocked spawn fails, "
          "open space connects, mobile Smartboard and curtains cannot collide)")


def main():
    p=argparse.ArgumentParser()
    p.add_argument("--luau",help="Pinned Luau executable from the classroom CI")
    p.add_argument("--out",type=Path,help="Optional nonproduction route evidence JSON")
    p.add_argument("--self-test",action="store_true")
    args=p.parse_args()
    if args.self_test:
        self_test()
        return
    if not args.luau:
        p.error("--luau required unless --self-test")
    result=inspect(get_source_blockers(args.luau))
    for name,route in result["routes"].items():
        print("STATIC_NAV_ROUTE_PASS",name,"length_studs="+str(route["length_studs"]),
              "end="+str(route["endpoint"]),flush=True)
    print("STATIC_NAV_ACCEPTED reachable_cells="+str(result["reachable_cells"]),
          "source_colliders="+str(result["blockers"]),
          "NATIVE_ROBLOX_DEVICE_QA_STILL_REQUIRED",flush=True)
    if args.out:
        args.out.parent.mkdir(parents=True,exist_ok=True)
        args.out.write_text(json.dumps(result,indent=2)+"\n",encoding="utf-8")

if __name__=="__main__":
    main()
