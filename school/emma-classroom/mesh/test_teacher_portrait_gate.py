#!/usr/bin/env python3
"""Regression tests for static private teacher GLB quality gate."""
from pathlib import Path
import tempfile
import unittest
import trimesh
from validate_teacher_portrait import inspect, matches_part


class PortraitModelGateTests(unittest.TestCase):
    def make_model(self, folder: Path, omit=""):
        scene=trimesh.Scene()
        parts=[
            ("head", (0,5.65,0),(.42,.55,.37)),
            ("torso_sweater", (0,4.05,0),(.65,.90,.33)),
            ("left_arm",(-.76,4.02,0),(.19,.80,.21)),
            ("right_arm",(.76,4.02,0),(.19,.80,.21)),
            ("left_hand",(-.76,3.16,-.1),(.13,.21,.13)),
            ("right_hand",(.76,3.16,-.1),(.13,.21,.13)),
            ("left_trouser",(-.28,1.62,0),(.30,1.46,.30)),
            ("right_trouser",(.28,1.62,0),(.30,1.46,.30)),
            ("left_shoe",(-.28,.12,-.2),(.24,.12,.44)),
            ("right_shoe",(.28,.12,-.2),(.24,.12,.44)),
            ("iris_left",(-.16,5.78,-.38),(.085,.065,.012)),
            ("iris_right",(.16,5.78,-.38),(.085,.065,.012)),
            ("bob_hair_lock",(0,6.02,.11),(.46,.32,.37))
        ]
        for name,centre,axes in parts:
            if name == omit or (omit=="eyes" and name.startswith("iris_")):
                continue
            m=trimesh.creation.icosphere(subdivisions=3)
            m.apply_scale(axes);m.apply_translation(centre)
            scene.add_geometry(m,geom_name=name,node_name=name)
        path=folder/"synthetic.glb"
        path.write_bytes(scene.export(file_type="glb"))
        return path

    def test_left_right_are_not_confused(self):
        self.assertTrue(matches_part("L_anatomical_palm","left_hand",("l_palm",)))
        self.assertFalse(matches_part("R_anatomical_palm","left_hand",("l_palm",)))
        self.assertTrue(matches_part("R_anatomical_palm","right_hand",("r_palm",)))
        self.assertFalse(matches_part("L_trousers","right_trouser",("r_leg",)))

    def test_sealed_geometry_passes_structural_gate(self):
        with tempfile.TemporaryDirectory() as d:
            report=inspect(self.make_model(Path(d)))
            self.assertEqual(report["problems"],[],report["problems"])
            self.assertTrue(report["passed"])

    def test_hand_missing_is_rejected(self):
        with tempfile.TemporaryDirectory() as d:
            report=inspect(self.make_model(Path(d),"right_hand"))
            self.assertIn("MISSING_ANATOMY:right_hand",report["problems"])
            self.assertFalse(report["passed"])

    def test_pasted_photo_without_3d_eyes_is_rejected(self):
        with tempfile.TemporaryDirectory() as d:
            report=inspect(self.make_model(Path(d),"eyes"))
            self.assertIn("NO_3D_EYE_GEOMETRY",report["problems"])

    def test_missing_file_is_rejected(self):
        report=inspect(Path("/missing/private-teacher.glb"))
        self.assertEqual(report["problems"],["GLB_FILE_NOT_FOUND"])


if __name__=="__main__":
    unittest.main()
