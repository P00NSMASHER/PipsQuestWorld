#!/usr/bin/env python3
"""Source-derived, conservative player-footprint navigation audit.

The real showroom Luau constructors run with the same geometry doubles as
the renderer. This is NOT Roblox physics, a native camera render, or a phone
test. We inspect CanCollide and transforms, conservatively project rotated
part bounds onto the floor, and require a connected route from the spawn to
all major parts of the classroom. Static floors and overhead fixtures do not
obstruct a standing avatar. A walk route must also have source-constructed,
collidable floor beneath every sampled cell; otherwise a 2D path can falsely
cross a void at the left classroom-to-hallway junction.

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
X_MIN, X_MAX = -55.0, 165.0
Z_MIN, Z_MAX = -32.0, 48.0
START = (5.0, 24.0)
GOALS = {
    "front_teaching_wall": (5.0, -24.0),
    "right_supply_closet_interior": (0.0, 31.0),
    "straight_staff_hall_entry": (56.0, 15.5),
    "photo_hallway_midpoint": (103.0, 15.5),
    "photo_hallway_far_end": (148.0, 15.5),
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


# Four genuine collidable floors support the classroom, closet, staff
# vestibule and long gallery. The preexisting closet laminate is now
# walkable: the relocated photo-gallery slab no longer sits beneath it.
# Decorative area rugs and noncolliding scenery never grant support.
SUPPORT_FLOOR_NAMES = frozenset({
    "Warm oak classroom floor",
    "Supply closet warm laminate floor",
    "Side hall floor",
    "Photo hall polished square stone floor",
})

@dataclass(frozen=True)
class FloorSupport:
    name: str
    xmin: float
    xmax: float
    zmin: float
    zmax: float
    top: float

    def supports(self, x: float, z: float) -> bool:
        return self.xmin <= x <= self.xmax and self.zmin <= z <= self.zmax


def assert_continuous_floor_segment(
    a: tuple[float, float] | list[float],
    b: tuple[float, float] | list[float],
    floors: list[FloorSupport],
) -> None:
    """Require no unsupported slit between adjacent grid nodes.

    The existing grid tests only the centers of cells separated by STEP.
    Two centers may rest on separate slabs despite a narrow uncovered gap
    between them. Intersect each real floor rectangle with the entire
    cardinal route segment and require its union to cover the interval.

    This proves continuous source-modeled support under the *route
    centerline*, not the full avatar foot/contact patch or native physics.
    """
    eps = 1e-6
    x0, z0 = map(float, a)
    x1, z1 = map(float, b)
    assert all(math.isfinite(v) for v in (x0, z0, x1, z1)), (
        "ROUTE_SEGMENT_NONFINITE")
    dx, dz = abs(x1 - x0), abs(z1 - z0)
    assert (dx <= eps) != (dz <= eps), (
        "ROUTE_SEGMENT_NONCARDINAL_OR_ZERO")
    assert max(dx, dz) <= STEP + eps, "ROUTE_SEGMENT_SKIPPED_GRID_STEP"
    assert floors, "ROUTE_SEGMENT_FLOOR_EVIDENCE_MISSING"

    if dx > eps:
        lo, hi = sorted((x0, x1))
        intervals = [
            (max(lo, f.xmin), min(hi, f.xmax))
            for f in floors
            if f.zmin - eps <= z0 <= f.zmax + eps
            and f.xmax >= lo and f.xmin <= hi
        ]
    else:
        lo, hi = sorted((z0, z1))
        intervals = [
            (max(lo, f.zmin), min(hi, f.zmax))
            for f in floors
            if f.xmin - eps <= x0 <= f.xmax + eps
            and f.zmax >= lo and f.zmin <= hi
        ]

    covered_until = lo
    for begin, end in sorted(intervals):
        if end <= covered_until + eps:
            continue
        if begin > covered_until + eps:
            break
        covered_until = max(covered_until, end)
        if covered_until >= hi - eps:
            return
    raise AssertionError(
        f"UNSUPPORTED_ROUTE_SEGMENT_GAP {tuple(a)}->{tuple(b)} "
        f"covered_to={covered_until:.5f} required_to={hi:.5f}"
    )


def assert_straight_staff_corridor(
    blockers: list[Blocker],
    floors: list[FloorSupport],
    *,
    start_x: float = 39.0,
    far_x: float = 150.0,
    center_z: float = 15.5,
) -> None:
    """Prove an actual uninterrupted eastbound walking tube, not a BFS detour.

    Ordinary reachability can pass a corridor containing a central divider
    because its route can weave around the wall. Here the player's nominal
    2-stud diameter must fit a SINGLE +X centerline from just outside the
    staff threshold to the distant photo gallery. Blocks are already inflated
    by AVATAR_RADIUS. Analytically union the source-constructed floor edges,
    also at the lateral edges of the standing footprint, to detect subgrid
    unsupported strips which a sample-only check could overlook.

    This is conservative source geometry, NOT native Roblox physics.
    """
    assert start_x >= 38 and far_x <= 160 and far_x > start_x + 90, (
        "STRAIGHT_HALL_INVALID_PROOF_SPAN")
    assert floors, "STRAIGHT_HALL_FLOOR_EVIDENCE_MISSING"
    for obstacle in blockers:
        if (obstacle.xmax >= start_x and obstacle.xmin <= far_x
                and obstacle.zmin <= center_z <= obstacle.zmax):
            raise AssertionError(
                f"STRAIGHT_HALL_CENTERLINE_BLOCKED {obstacle.name} "
                f"x={obstacle.xmin:.2f}..{obstacle.xmax:.2f}")

    # Support both edges and the center of the full avatar foot patch,
    # across the entire 111-stud route. No 0.75-stud grid hiding gaps.
    for z in (center_z - AVATAR_RADIUS, center_z,
              center_z + AVATAR_RADIUS):
        intervals = sorted((max(start_x, floor.xmin),
                            min(far_x, floor.xmax))
                           for floor in floors
                           if floor.zmin <= z <= floor.zmax
                           and floor.xmax >= start_x
                           and floor.xmin <= far_x)
        edge = start_x
        for lo, hi in intervals:
            if hi <= edge + 1e-6:
                continue
            if lo > edge + 1e-6:
                break
            edge = max(edge, hi)
            if edge >= far_x - 1e-6:
                break
        assert edge >= far_x - 1e-6, (
            f"STRAIGHT_HALL_UNSUPPORTED_FOOTPRINT z={z:.2f} "
            f"supported_until_x={edge:.5f}")


def as_floor_supports(rows: list[list[str]]) -> list[FloorSupport]:
    """Read the real Luau-generated collidable floor parts, never source guesses."""
    floors = {}
    for row in rows:
        if len(row) < 2 or row[1] not in SUPPORT_FLOOR_NAMES:
            continue
        assert len(row) == 17, "SUPPORT_FLOOR_MALFORMED_EVIDENCE"
        _, name, *raw = row
        assert name not in floors, "SUPPORT_FLOOR_DUPLICATE " + name
        sx, sy, sz, px, py, pz, *matrix = map(float, raw)
        assert all(math.isfinite(v) for v in (sx, sy, sz, px, py, pz, *matrix)), (
            "SUPPORT_FLOOR_NONFINITE " + name)
        assert sx > 0 and sy > 0 and sz > 0, "SUPPORT_FLOOR_ZERO_DIMENSION " + name
        # Cardinal yaw keeps a rectangular floor axis-aligned. A quarter
        # turn swaps its world X/Z extents; pitch, roll and diagonal slabs
        # still fail rather than granting support over empty space.
        assert (abs(matrix[4]-1) < .001 and
                all(abs(matrix[i]) < .001 for i in (1,3,5,7)) and
                all(min(abs(v),abs(abs(v)-1)) < .001
                    for v in (matrix[0],matrix[2],matrix[6],matrix[8])) and
                abs(matrix[0]*matrix[8]-matrix[2]*matrix[6]-1)<.001), (
            "SUPPORT_FLOOR_TILTED_UNMODELED " + name)
        top = py + sy / 2
        assert abs(top-0.5) <= 0.08, "SUPPORT_FLOOR_BAD_ELEVATION " + name
        world_x = abs(matrix[0])*sx + abs(matrix[2])*sz
        world_z = abs(matrix[6])*sx + abs(matrix[8])*sz
        floors[name] = FloorSupport(name, px-world_x/2, px+world_x/2,
                                    pz-world_z/2, pz+world_z/2, top)
    assert set(floors) == SUPPORT_FLOOR_NAMES, (
        "SUPPORT_FLOOR_MISSING " + str(sorted(SUPPORT_FLOOR_NAMES-set(floors))))
    return [floors[name] for name in sorted(floors)]


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
    def __init__(self, blockers: list[Blocker],
                 floors: list[FloorSupport] | None = None):
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
        if floors is not None:
            assert floors, "SUPPORT_FLOORS_REQUIRED"
            for ix in range(self.w):
                x = X_MIN + ix*STEP
                for iz in range(self.h):
                    z = Z_MIN + iz*STEP
                    if not any(f.supports(x,z) for f in floors):
                        self.blocked.add((ix,iz))

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


def inspect(blockers: list[Blocker],
            floors: list[FloorSupport] | None = None) -> dict:
    assert blockers, "No physical colliders exported; source probe is not valid"
    grid=Grid(blockers, floors)
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
    segment_count = 0
    if floors is not None:
        for name,route in routes.items():
            points = route["waypoints"]
            assert all(any(f.supports(x,z) for f in floors)
                       for x,z in points), (
                "UNSUPPORTED_ROUTE_WAYPOINT " + name)
            for a, b in zip(points, points[1:]):
                try:
                    assert_continuous_floor_segment(a, b, floors)
                except AssertionError as exc:
                    raise AssertionError(
                        f"UNSUPPORTED_ROUTE_CONTINUITY route={name} {exc}"
                    ) from exc
                segment_count += 1
    # The user explicitly requires a straight route out the staff doorway:
    # all exterior route waypoints remain inside the same east-west corridor.
    # No northward swing around the supply closet and no rear-door shortcut.
    for name in ("photo_hallway_midpoint","photo_hallway_far_end"):
        points=routes[name]["waypoints"]
        assert any(x>=37.5 and 10<=z<=24 for x,z in points), (
            "LEFT_STAFF_HALL_MISSING_FROM_ROUTE: "+name
        )
        assert any(x>=65 and 10<=z<=23 for x,z in points), (
            "STRAIGHT_HALL_AXIS_NOT_REACHED: "+name
        )
        assert all(5.5<=z<=26.0 for x,z in points if x>=38.0), (
            "STRAIGHT_HALL_UNWANTED_NORTH_TURN: "+name
        )
        assert all(x<=162 for x,z in points), (
            "STRAIGHT_HALL_FAR_END_WALL_LEAK: "+name
        )
    assert all(x<37.5 for x,z in routes["right_supply_closet_interior"]["waypoints"]), (
        "RIGHT_CLOSET_MUST_BE_REACHED_FROM_CLASSROOM_NOT_HALL"
    )
    assert any(b.name=="Supply closet solid rear wall" and b.covers(0.0,36.05)
               for b in blockers), (
        "REAR_CLOSET_WALL_MISSING_RIGHT_DOUBLE_DOOR_LEAKS_TO_HALL"
    )
    return {
        "mode":"source-derived static approximate footprints; not native Roblox physics",
        "grid_studs":STEP,
        "avatar_radius_studs":AVATAR_RADIUS,
        "reachable_cells":len(distance),
        "blockers":len(blockers),
        "structural_support_floors": sorted(f.name for f in floors) if floors is not None else None,
        "all_waypoints_floor_supported": floors is not None,
        "all_route_segments_continuously_supported": floors is not None,
        "validated_route_segments": segment_count,
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
                          or row[1]=="Classroom faith window banner"
                      )})
    assert not offenders, (
        "Photo-only school window drapes must remain noncolliding: "
        + ", ".join(offenders)
    )


def assert_no_supply_bin_colliders(rows: list[list[str]]) -> None:
    decorative={"Cubbie bin", "Bin side", "Bin front and back",
                "Bin label", "Stored classroom file folder"}
    offenders=sorted({row[1] for row in rows if len(row)>1
                      and row[1] in decorative})
    assert not offenders, (
        "Decorative school storage bins/folders must remain noncolliding: "
        + ", ".join(offenders)
    )


def assert_no_corridor_finishing_colliders(rows: list[list[str]]) -> None:
    # Architecture that terminates the hall is collidable. The thin
    # noticeboards, rail trim and fixture covers must never become blockers.
    decorative = {
        "Rear hall pinned notice", "Rear hall notice heading",
        "Rear hall brass notice pin", "Rear hall dado cap rail",
        "Rear hall fluorescent metal surround",
        "Staff hall framed announcement board",
        "Staff hall inset cork noticeboard",
        "Staff hall anonymous paper notice",
        "Photo hall anonymous diamond student display",
        "Photo hall adjacent oak door",
        "Photo hall adjacent frosted door glass",
        "Photo hall adjacent oak side stile",
        "Photo hall adjacent oak upper lintel",
        "Photo hall adjacent oak glass sill",
        "Photo hall adjacent oak glass crossbar",
        "Photo hall adjacent lower raised wood panel",
        "Photo hall adjacent brass push plate",
        "Photo hall adjacent brass pull",
        "Side hall fluorescent metal surround",
        "Hall fluorescent light", "Side hall fluorescent",
    }
    offenders=sorted({row[1] for row in rows
                      if len(row)>1 and row[1] in decorative})
    assert not offenders, (
        "Noncolliding school corridor finishing became a walk obstruction: "
        + ", ".join(offenders)
    )


def assert_no_chair_vent_colliders(rows: list[list[str]]) -> None:
    offenders=sorted({row[1] for row in rows if len(row)>1
                      and row[1]=="Student chair ventilation inset"})
    assert not offenders, (
        "Decorative chair vents must remain noncolliding: "
        + ", ".join(offenders)
    )


def get_source_geometry(luau: str) -> tuple[list[Blocker],list[FloorSupport]]:
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
    assert_no_supply_bin_colliders(rows)
    assert_no_corridor_finishing_colliders(rows)
    assert_no_chair_vent_colliders(rows)
    return as_blockers(rows), as_floor_supports(rows)


def get_source_blockers(luau: str) -> list[Blocker]:
    # Preserve compatibility with child-eye camera provenance checks.
    return get_source_geometry(luau)[0]


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
    # A void is not a hallway, even without a collidable wall. Preserve
    # the historical obstacle-only grid for its other documented uses.
    support = FloorSupport("fixture", START[0]-2, START[0]+2,
                           START[1]-2, START[1]+2, 0.5)
    supported = Grid([], [support])
    safe,_ = supported.connected(START)
    assert supported.xy(START) in safe, "SUPPORTED_START_REJECTED"
    assert supported.xy((START[0]+4, START[1])) not in safe, (
        "UNSUPPORTED_VOID_WAS_TRAVERSABLE")
    try:
        Grid([], []).connected(START)
    except AssertionError as exc:
        assert "SUPPORT_FLOORS_REQUIRED" in str(exc)
    else:
        raise AssertionError("EMPTY_SUPPORT_LIST_ACCEPTED")
    # Floor evidence must be complete and from actual collidable geometry.
    fixture_names = sorted(SUPPORT_FLOOR_NAMES)
    fixtures = [[*flat[:1], name, *flat[2:]] for name in fixture_names]
    assert len(as_floor_supports(fixtures)) == 4
    # Same horizontal slab turned exactly 180 degrees is still physical
    # support. Reject a slight tip instead of silently granting air routes.
    rotated = list(fixtures[0])
    rotated[-9:] = ["-1","0","0","0","1","0","0","0","-1"]
    assert len(as_floor_supports([rotated,*fixtures[1:]]))==4
    quarter = list(fixtures[0])
    quarter[2:5] = ["8","1","20"]
    quarter[-9:] = ["0","0","1","0","1","0","-1","0","0"]
    turned = next(f for f in as_floor_supports([quarter,*fixtures[1:]])
                  if f.name==fixture_names[0])
    assert abs(turned.xmax-turned.xmin-20)<.001
    assert abs(turned.zmax-turned.zmin-8)<.001
    tipped = list(fixtures[0])
    tipped[-9:] = ["0.99","0.14","0","-0.14","0.99","0","0","0","1"]
    try:
        as_floor_supports([tipped,*fixtures[1:]])
    except AssertionError as exc:
        assert "SUPPORT_FLOOR_TILTED_UNMODELED" in str(exc)
    else:
        raise AssertionError("TILTED_REAL_FLOOR_FALSELY_SUPPORTED")
    try:
        as_floor_supports(fixtures[:2])
    except AssertionError as exc:
        assert "SUPPORT_FLOOR_MISSING" in str(exc)
    else:
        raise AssertionError("MISSING_REAL_FLOOR_ACCEPTED")
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
    assert_no_supply_bin_colliders([flat,tall])
    try:
        assert_no_supply_bin_colliders([
            ["NAV","Stored classroom file folder",*flat[2:]]
        ])
        raise AssertionError("Colliding bin folder test was accepted")
    except AssertionError as e:
        assert "noncolliding" in str(e)
    assert_no_corridor_finishing_colliders([flat,tall])
    for bad_name in ("Photo hall anonymous diamond student display",
                     "Rear hall pinned notice",
                     "Staff hall anonymous paper notice",
                     "Hall fluorescent light"):
        try:
            assert_no_corridor_finishing_colliders([
                ["NAV",bad_name,*flat[2:]]
            ])
            raise AssertionError("Colliding hall decoration was accepted")
        except AssertionError as e:
            assert "walk obstruction" in str(e)
    assert_no_chair_vent_colliders([flat,tall])
    try:
        assert_no_chair_vent_colliders([
            ["NAV","Student chair ventilation inset",*flat[2:]]
        ])
        raise AssertionError("Colliding chair vent test accepted")
    except AssertionError as exc:
        assert "noncolliding" in str(exc)
    # The old 0.75-stud grid sees both endpoints as safe while missing the
    # narrow actual void between them. Analytic interval coverage must fail.
    gap_floors = [
        FloorSupport("before", -1, .29, -1, 1, .5),
        FloorSupport("after", .47, 2, -1, 1, .5),
    ]
    assert all(any(f.supports(x, 0) for f in gap_floors) for x in (0, STEP)), (
        "GAP_FIXTURE_DID_NOT_FOOL_ORIGINAL_GRID")
    try:
        assert_continuous_floor_segment((0, 0), (STEP, 0), gap_floors)
    except AssertionError as exc:
        assert "UNSUPPORTED_ROUTE_SEGMENT_GAP" in str(exc)
    else:
        raise AssertionError("SUB_GRID_FLOOR_GAP_FALSELY_ACCEPTED")
    # Exact touching slabs and overlapping slabs have zero missing support.
    for edge in (.29, .52):
        continuous = [
            FloorSupport("before", -1, edge, -1, 1, .5),
            FloorSupport("after", .29, 2, -1, 1, .5),
        ]
        assert_continuous_floor_segment((0, 0), (STEP, 0), continuous)
        assert_continuous_floor_segment((STEP, 0), (0, 0), continuous)
    # A narrow z-axis gap must not slip through the x-axis-only case.
    z_gap = [
        FloorSupport("south", -1, 1, -1, .29, .5),
        FloorSupport("north", -1, 1, .47, 2, .5),
    ]
    try:
        assert_continuous_floor_segment((0, 0), (0, STEP), z_gap)
    except AssertionError as exc:
        assert "UNSUPPORTED_ROUTE_SEGMENT_GAP" in str(exc)
    else:
        raise AssertionError("Z_AXIS_SUB_GRID_GAP_FALSELY_ACCEPTED")
    for a, b, evidence, error in [
        ((0, 0), (STEP, 0), [], "FLOOR_EVIDENCE_MISSING"),
        ((0, 0), (STEP, STEP), gap_floors, "NONCARDINAL"),
        ((0, 0), (0, 0), gap_floors, "NONCARDINAL"),
        ((0, 0), (STEP * 2, 0), gap_floors, "SKIPPED_GRID_STEP"),
        ((0, 0), (STEP, 0),
         [FloorSupport("short", -1, .1, -1, 1, .5)], "SEGMENT_GAP"),
    ]:
        try:
            assert_continuous_floor_segment(a, b, evidence)
        except AssertionError as exc:
            assert error in str(exc), (error, str(exc))
        else:
            raise AssertionError("BAD_ROUTE_SEGMENT_FALSELY_ACCEPTED " + error)
    print("CONTINUOUS_FLOOR_ADVERSARIAL_PASS "
          "sub_grid_x_and_z_gaps,missing_floor,diagonal,zero_step,"
          "skipped_step,unsupported_end_rejected=true")

    # Four adversarial source-equivalent fixtures prove that a reachable
    # corridor cannot conceal a turn, missing floor strip or side-foot void.
    tube_floors = [
        FloorSupport("staff", 36.5, 54.5, 4.25, 27.3, .48),
        FloorSupport("gallery", 54.0, 162.0, 4.25, 26.75, .50),
    ]
    assert_straight_staff_corridor([], tube_floors)
    straight_mutations = [
        ("mid_gallery_divider",
         [Blocker("synthetic cross-wall", 87.0, 89.0, 14.5, 16.5)],
         tube_floors,
         "STRAIGHT_HALL_CENTERLINE_BLOCKED"),
        ("staff_to_gallery_subgrid_gap",
         [],
         [FloorSupport("staff", 36.5, 53.8, 4.25, 27.3, .48),
          tube_floors[1]],
         "STRAIGHT_HALL_UNSUPPORTED_FOOTPRINT"),
        ("unsupported_outer_foot",
         [],
         [FloorSupport("staff", 36.5, 54.5, 15.0, 16.0, .48),
          FloorSupport("gallery", 54.0, 162.0, 15.0, 16.0, .50)],
         "STRAIGHT_HALL_UNSUPPORTED_FOOTPRINT"),
        ("gallery_offset_out_of_line",
         [],
         [tube_floors[0],
          FloorSupport("gallery", 54.0, 162.0, 27.5, 48.0, .50)],
         "STRAIGHT_HALL_UNSUPPORTED_FOOTPRINT"),
    ]
    for label, synthetic_blockers, synthetic_floors, expected in straight_mutations:
        try:
            assert_straight_staff_corridor(synthetic_blockers, synthetic_floors)
        except AssertionError as exc:
            assert expected in str(exc), (label, str(exc))
        else:
            raise AssertionError("STRAIGHT_HALL_NEGATIVE_TEST_ACCEPTED " + label)
    print("STRAIGHT_HALL_CENTERLINE_SELF_TEST_PASS "
          "wall,gap,footprint,offset_gallery_rejected=true")

    print("STATIC_NAV_SELF_TEST_PASS structural_floor_support_enforced=true "
          "unsupported_void_and_missing_floor_rejected=true "
          "colliders_and_decorative_obstructions_checked=true")


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
    blockers,floors=get_source_geometry(args.luau)
    result=inspect(blockers,floors)
    assert_straight_staff_corridor(blockers,floors)
    print("STRAIGHT_HALL_CENTERLINE_SOURCE_PASS no_turns=true "
          "source_colliders_clear=true avatar_footprint_fully_supported=true "
          "native_roblox_device_qa_still_required=true",flush=True)
    # Deliberately reopen a physical x-axis gap at the old eastbound seam.
    # This catches "air routes" on the nominal 0.75-stud navigation grid.
    former=[FloorSupport(f.name,f.xmin,
                         53.5 if f.name=="Side hall floor" else f.xmax,
                         f.zmin,f.zmax,f.top) for f in floors]
    try:
        inspect(blockers,former)
    except AssertionError as exc:
        assert "BLOCKED_NAVIGATION" in str(exc) or "LEFT_STAFF" in str(exc), (
            "FLOOR_GAP_NEGATIVE_UNEXPECTED " + str(exc))
    else:
        raise AssertionError("FORMER_UNSUPPORTED_JUNCTION_FALSELY_ACCEPTED")
    print("SUPPORTED_ROUTE_ADVERSARIAL_PASS former_eastbound_seam_rejected=true",
          flush=True)
    for name,route in result["routes"].items():
        print("STATIC_NAV_ROUTE_PASS",name,"length_studs="+str(route["length_studs"]),
              "end="+str(route["endpoint"]),flush=True)
    print("SUPPORTED_ROUTE_SOURCE_PASS four_constructed_collidable_floors=true "
          "all_nine_routes_floor_supported=true",flush=True)
    print("CONTINUOUS_FLOOR_ROUTE_PASS "
          "routes=" + str(len(result["routes"])) +
          " cardinal_segments=" + str(result["validated_route_segments"]) +
          " all_route_centerlines_source_supported=true "
          "native_roblox_device_qa_still_required=true", flush=True)
    print("DOORWAY_ROUTING_NAV_PASS straight_left_staff_exit=true "
          "right_rear_supply_closet_sealed=true",flush=True)
    print("STATIC_NAV_ACCEPTED reachable_cells="+str(result["reachable_cells"]),
          "source_colliders="+str(result["blockers"]),
          "NATIVE_ROBLOX_DEVICE_QA_STILL_REQUIRED",flush=True)
    if args.out:
        args.out.parent.mkdir(parents=True,exist_ok=True)
        args.out.write_text(json.dumps(result,indent=2)+"\n",encoding="utf-8")

if __name__=="__main__":
    main()
