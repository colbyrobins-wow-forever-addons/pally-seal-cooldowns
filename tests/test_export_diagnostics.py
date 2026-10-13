"""Tests for exporting captures without running SavedVariables code."""

import tempfile
import unittest
from pathlib import Path

from scripts.export_diagnostics import export_diagnostics, extract_diagnostics


class ExportDiagnosticsTests(unittest.TestCase):
    """Verify export boundaries, decoding, and failure behavior."""

    def test_extracts_only_capture_and_decodes_strings(self) -> None:
        source = r'''
PallySealCooldownsDB = {
    ["privateSetting"] = "not exported",
    ["debugLog"] = {
        "1.0 seal-names Seal of Righteousness",
        "2.0 cast \"Seal\" C:\\test",
        "3.0 name=\195\169",
    },
}
error("Never execute this file")
'''
        self.assertEqual(extract_diagnostics(source), [
            "1.0 seal-names Seal of Righteousness", '2.0 cast "Seal" C:\\test',
            "3.0 name=é",
        ])

    def test_rejects_missing_empty_malformed_and_oversized_capture(self) -> None:
        cases = ["", '["debugLog"] = {\n}', '["debugLog"] = {\n os.execute("x")\n}',
                 '["debugLog"] = {\n' + '"entry",\n' * 101 + '}']
        for source in cases:
            with self.subTest(source=source[:40]), self.assertRaises(ValueError):
                extract_diagnostics(source)

    def test_exports_indexed_entries_and_preserves_existing_output_on_failure(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory) / "saved.lua"
            output = Path(directory) / "capture.txt"
            source.write_text('["debugLog"] = {\n [1] = "scan empty",\n}', encoding="utf-8")
            self.assertEqual(export_diagnostics(source, output), 1)
            self.assertIn("scan empty", output.read_text(encoding="utf-8"))
            original = output.read_bytes()
            source.write_text("no capture", encoding="utf-8")
            with self.assertRaises(ValueError):
                export_diagnostics(source, output)
            self.assertEqual(output.read_bytes(), original)
            with self.assertRaises(ValueError):
                export_diagnostics(source, source)


if __name__ == "__main__":
    unittest.main()
