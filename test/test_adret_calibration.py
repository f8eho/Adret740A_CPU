#!/usr/bin/env python3
"""Tests hors matériel de l'application de calibration unifiée."""

from __future__ import annotations

import json
from pathlib import Path
import sys
import tempfile
import unittest


sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "scripts"))

import adret_calibration as calibration  # noqa: E402


class CalibrationToolTests(unittest.TestCase):
    def test_selection_and_representative_points(self) -> None:
        self.assertEqual(calibration.parse_selection("0,2-4", 5), [0, 2, 3, 4])
        self.assertEqual(calibration.representative_frequency(29), 560_000_000)
        self.assertEqual(calibration.representative_frequency(30), 635_000_000)
        self.assertEqual(calibration.representative_frequency(40), 1_115_000_000)
        self.assertEqual(calibration.representative_amplitude(27), -1290)

    def test_erased_2816_is_a_neutral_table(self) -> None:
        data = bytes([0xFF]) * calibration.EEPROM_SIZE
        analysis = calibration.analyze_2816(data)
        self.assertEqual(analysis.minimum, 0)
        self.assertEqual(analysis.maximum, 0)
        self.assertTrue(any("effacé" in warning for warning in analysis.warnings))

    def test_completed_overlay_is_added_to_the_base(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            base_path = root / "base.inc"
            session_path = root / "session.json"
            output_path = root / "merged.inc"
            base_path.write_text("0\n", encoding="utf-8")
            base = calibration.read_table(base_path)
            overlay = {
                f"{row}:{step}": 0
                for row in range(calibration.ROWS)
                for step in range(calibration.STEPS)
            }
            overlay["2:3"] = 4
            session_path.write_text(
                json.dumps(
                    {
                        "status": "complete",
                        "base_crc": f"{calibration.crc16(base):X}",
                        "overlay": overlay,
                    }
                ),
                encoding="utf-8",
            )

            result = calibration.merge_session(
                session_path, base_path, output_path, False
            )

            self.assertEqual(result, 0)
            merged = calibration.read_table(output_path)
            self.assertEqual(merged[2 * calibration.ROW_STRIDE + 3], 4)
            self.assertEqual(sum(merged), 4)
            self.assertEqual(
                calibration.read_table_profile(output_path), "base"
            )

    def test_import_requires_profile_and_rejects_unknown_extension(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            dump_path = root / "dump.bin"
            output_path = root / "CalibrationTable.inc"
            data = bytearray([0xFF]) * calibration.EEPROM_SIZE
            data[30 * calibration.ROW_STRIDE] = 0xFE
            dump_path.write_bytes(data)

            self.assertEqual(
                calibration.import_2816(dump_path, output_path, False), 1
            )
            self.assertEqual(
                calibration.import_2816(
                    dump_path, output_path, False, "base"
                ),
                1,
            )
            self.assertEqual(
                calibration.import_2816(
                    dump_path, output_path, False, "x2"
                ),
                0,
            )
            self.assertEqual(calibration.read_table_profile(output_path), "x2")

            data[41 * calibration.ROW_STRIDE] = 0xFE
            dump_path.write_bytes(data)
            second_output = root / "second" / "CalibrationTable.inc"
            self.assertEqual(
                calibration.import_2816(
                    dump_path, second_output, False, "x2"
                ),
                1,
            )


if __name__ == "__main__":
    unittest.main()
