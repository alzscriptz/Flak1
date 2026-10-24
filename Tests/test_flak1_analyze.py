import importlib.util
import tempfile
import unittest
from pathlib import Path

MODULE_PATH = Path(__file__).parents[1] / "Tools" / "flak1_analyze.py"
spec = importlib.util.spec_from_file_location("flak1_analyze", MODULE_PATH)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class PatternTests(unittest.TestCase):
    def test_wildcard_scan(self):
        data = bytes.fromhex("90 48 8B 11 22 89 90 48 8B AA BB 89")
        self.assertEqual(module.scan(data, module.parse_pattern("48 8B ?? ?? 89")), [1, 7])

    def test_pattern_validation(self):
        with self.assertRaises(ValueError):
            module.parse_pattern("48 GG")
        with self.assertRaises(ValueError):
            module.scan(b"abcdef", module.parse_pattern("?? ??"))

    def test_elf_identification(self):
        data = bytearray(64)
        data[:6] = b"\x7fELF\x02\x01"
        data[18:20] = (62).to_bytes(2, "little")
        result = module.identify(bytes(data))
        self.assertEqual(result["format"], "ELF")
        self.assertEqual(result["architecture"], "x86_64")
        self.assertEqual(result["bits"], 64)

    def test_pe_identification(self):
        data = bytearray(256)
        data[:2] = b"MZ"
        data[0x3c:0x40] = (0x80).to_bytes(4, "little")
        data[0x80:0x84] = b"PE\0\0"
        data[0x84:0x86] = (0x8664).to_bytes(2, "little")
        data[0x94:0x96] = (0xF0).to_bytes(2, "little")
        data[0x98:0x9A] = (0x20B).to_bytes(2, "little")
        result = module.identify(bytes(data))
        self.assertEqual(result["format"], "PE")
        self.assertEqual(result["architecture"], "x86_64")
        self.assertEqual(result["bits"], 64)

    def test_analyze_report_hash_and_strings(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "sample.bin"
            path.write_bytes(b"\x00HELLO_WORLD\x00" + bytes.fromhex("48 8B 00"))
            result = module.analyze(path, ["48 8B ??"], 10)
            self.assertEqual(result["input"]["size_bytes"], path.stat().st_size)
            self.assertTrue(result["input"]["sha256"])
            self.assertEqual(result["signatures"][0]["file_offsets_hex"], ["0xD"])
            self.assertTrue(any(item["text"] == "HELLO_WORLD" for item in result["strings"]))


if __name__ == "__main__":
    unittest.main()
