#!/usr/bin/env python3
"""Run full scene export against the thin-print rug and rejected old geometry."""
from __future__ import annotations
import argparse,contextlib,io,tempfile
from pathlib import Path
import export_source_scene as scene

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--luau',required=True)
    args=parser.parse_args();original=scene.generate_luau
    source=original();anchor='local total=0';assert source.count(anchor)==1
    cases={
        'old_raised_clouds':'''for _,p in ipairs(Room.Root:GetDescendants()) do
            if p.Name=="Photo rug number cloud body" then p.Size=Vector3.new(1.14,.12,.65);p.CFrame=CFrame.new(p.Position.X,.690,p.Position.Z)
            elseif p.Name=="Photo rug number cloud lobe" then p.Size=Vector3.new(.12,.94,.94);p.CFrame=CFrame.new(p.Position.X,.690,p.Position.Z)*CFrame.Angles(0,0,math.pi/2)
            elseif p.Name=="Photo rug number cloud numeral" then p.CFrame=CFrame.new(p.Position.X,.820,p.Position.Z) end
        end''',
        'floating_numbers':'''for _,p in ipairs(Room.Root:GetDescendants()) do if p.Name=="Photo rug number cloud numeral" then p.CFrame=CFrame.new(p.Position.X,.820,p.Position.Z) end end''',
        'sunken_clouds':'''for _,p in ipairs(Room.Root:GetDescendants()) do if p.Name=="Photo rug number cloud body" or p.Name=="Photo rug number cloud lobe" then p.CFrame=CFrame.new(0,-.035,0)*p.CFrame end end''',
        'opaque_number_stickers':'''for _,p in ipairs(Room.Root:GetDescendants()) do if p.Name=="Photo rug number cloud numeral" then p.Transparency=0 end end''',
    }
    with tempfile.TemporaryDirectory(prefix='emma-flat-rug-') as tmp:
        output=Path(tmp)/'scene.rbxmx'
        with contextlib.redirect_stdout(io.StringIO()):scene.export_scene(args.luau,output)
        assert output.exists() and output.stat().st_size>0
        print('FLAT_RUG_COMPLETE_EXPORT_PASS',flush=True)
        try:
            for name,mutation in cases.items():
                scene.generate_luau=lambda m=mutation:source.replace(anchor,m+'\n'+anchor)
                try:
                    with contextlib.redirect_stdout(io.StringIO()):scene.export_scene(args.luau,output)
                except AssertionError:
                    print('FLAT_RUG_SOURCE_NEGATIVE_REJECTED '+name,flush=True)
                else:raise RuntimeError('FLAT_RUG_FALSE_ACCEPT '+name)
        finally:scene.generate_luau=original
    print('FLAT_RUG_SOURCE_REGRESSION_PASS full_export_and_four_mutations=true',flush=True)
if __name__=='__main__':main()
