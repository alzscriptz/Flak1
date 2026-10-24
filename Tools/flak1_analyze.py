#!/usr/bin/env python3
"""Flak1 offline binary triage and signature scanner.

Reads files selected by the operator; it never attaches to or reads another process.
Supports format identification, basic PE/ELF/Mach-O metadata, printable strings,
and wildcard byte-pattern scans. This is a triage layer, not a disassembler.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import struct
import sys
from pathlib import Path
from typing import Any

MAX_FILE_SIZE = 1024 * 1024 * 1024
STRING_RE = re.compile(rb"[\x20-\x7e]{5,}")


def identify(data: bytes) -> dict[str, Any]:
    result: dict[str, Any] = {"format": "unknown", "architecture": None, "bits": None, "endianness": None}
    if len(data) >= 20 and data[:4] == b"\x7fELF":
        bits = {1: 32, 2: 64}.get(data[4])
        endian = {1: "little", 2: "big"}.get(data[5])
        result.update(format="ELF", bits=bits, endianness=endian)
        if bits and endian:
            order = "<" if endian == "little" else ">"
            try:
                machine = struct.unpack_from(order + "H", data, 18)[0]
                result["architecture"] = {3: "x86", 8: "MIPS", 20: "PowerPC", 21: "PowerPC64", 40: "ARM", 62: "x86_64", 183: "AArch64", 243: "RISC-V"}.get(machine, f"ELF machine {machine}")
                result["machine_id"] = machine
            except struct.error:
                result["parse_warning"] = "Truncated ELF header"
        return result
    if len(data) >= 64 and data[:2] == b"MZ":
        result["format"] = "PE"
        try:
            pe_offset = struct.unpack_from("<I", data, 0x3c)[0]
            if pe_offset + 24 <= len(data) and data[pe_offset:pe_offset + 4] == b"PE\0\0":
                machine, sections, timestamp, _, _, optional_size, characteristics = struct.unpack_from("<HHIIIHH", data, pe_offset + 4)
                result.update(machine_id=machine, section_count=sections, pe_timestamp=timestamp, characteristics=characteristics)
                result["architecture"] = {0x14c: "x86", 0x8664: "x86_64", 0x1c0: "ARM", 0xaa64: "ARM64"}.get(machine, f"PE machine 0x{machine:04x}")
                if optional_size >= 2 and pe_offset + 24 + optional_size <= len(data):
                    magic = struct.unpack_from("<H", data, pe_offset + 24)[0]
                    result["bits"] = {0x10b: 32, 0x20b: 64}.get(magic)
                result["endianness"] = "little"
            else:
                result["parse_warning"] = "MZ header found, but PE signature is absent or truncated"
        except struct.error:
            result["parse_warning"] = "Truncated PE header"
        return result
    if len(data) >= 8:
        magic = data[:4]
        mach = {
            b"\xfe\xed\xfa\xce": ("Mach-O", 32, "big"),
            b"\xce\xfa\xed\xfe": ("Mach-O", 32, "little"),
            b"\xfe\xed\xfa\xcf": ("Mach-O", 64, "big"),
            b"\xcf\xfa\xed\xfe": ("Mach-O", 64, "little"),
            b"\xca\xfe\xba\xbe": ("Mach-O Universal/FAT", None, "big"),
            b"\xbe\xba\xfe\xca": ("Mach-O Universal/FAT", None, "little"),
        }
        if magic in mach:
            fmt, bits, endian = mach[magic]
            cpu = struct.unpack_from(">I" if endian == "big" else "<I", data, 4)[0]
            result.update(format=fmt, bits=bits, endianness=endian, cpu_type=cpu,
                          architecture={7: "x86", 0x01000007: "x86_64", 12: "ARM", 0x0100000c: "ARM64"}.get(cpu, f"Mach CPU {cpu}"))
    return result


def parse_pattern(pattern: str) -> list[int | None]:
    tokens = pattern.strip().split()
    if not tokens:
        raise ValueError("Pattern cannot be empty")
    parsed: list[int | None] = []
    for token in tokens:
        if token in ("?", "??"):
            parsed.append(None)
        elif re.fullmatch(r"[0-9a-fA-F]{2}", token):
            parsed.append(int(token, 16))
        else:
            raise ValueError(f"Invalid pattern token: {token!r}; use two hex digits or ??")
    return parsed


def scan(data: bytes, pattern: list[int | None], limit: int = 10000) -> list[int]:
    size = len(pattern)
    if size > len(data):
        return []
    fixed = [(i, b) for i, b in enumerate(pattern) if b is not None]
    if not fixed:
        raise ValueError("Pattern must contain at least one concrete byte")
    hits: list[int] = []
    # Anchor on the last concrete byte to reduce candidate checks.
    anchor_i, anchor_b = fixed[-1]
    start = 0
    while len(hits) < limit:
        pos = data.find(bytes([anchor_b]), start + anchor_i)
        if pos < 0:
            break
        candidate = pos - anchor_i
        start = candidate + 1
        if candidate < 0 or candidate + size > len(data):
            continue
        if all(data[candidate + i] == b for i, b in fixed):
            hits.append(candidate)
    return hits


def analyze(path: Path, patterns: list[str], string_limit: int) -> dict[str, Any]:
    size = path.stat().st_size
    if size > MAX_FILE_SIZE:
        raise ValueError(f"File exceeds safety limit of {MAX_FILE_SIZE} bytes")
    data = path.read_bytes()
    if not data:
        raise ValueError("Input file is empty")
    info = {
        "schema_version": "1.0",
        "input": {"name": path.name, "size_bytes": len(data), "sha256": hashlib.sha256(data).hexdigest()},
        "binary": identify(data),
        "strings": [],
        "signatures": [],
        "scope": {
            "mode": "offline file analysis",
            "process_memory_read": False,
            "runtime_offsets_inferred": False,
            "note": "Matches are file offsets, not runtime addresses. Validate any hypothesis independently."
        }
    }
    for match in STRING_RE.finditer(data):
        if len(info["strings"]) >= string_limit:
            break
        info["strings"].append({"file_offset": match.start(), "text": match.group().decode("ascii", "replace")})
    for raw in patterns:
        pat = parse_pattern(raw)
        hits = scan(data, pat)
        info["signatures"].append({"pattern": raw, "match_count": len(hits), "file_offsets_hex": [f"0x{x:X}" for x in hits]})
    return info


def main() -> int:
    parser = argparse.ArgumentParser(description="Offline PE/ELF/Mach-O triage, printable strings, and wildcard AOB scans.")
    parser.add_argument("file", type=Path, help="Local binary or authorized capture file")
    parser.add_argument("--pattern", action="append", default=[], help='AOB pattern, e.g. "48 8B ?? ?? 89" (repeatable)')
    parser.add_argument("--strings-limit", type=int, default=2000, help="Maximum printable strings to include (default: 2000)")
    parser.add_argument("--output", "-o", type=Path, help="Write JSON report to this path; otherwise print to stdout")
    args = parser.parse_args()
    if args.strings_limit < 0 or args.strings_limit > 100000:
        parser.error("--strings-limit must be between 0 and 100000")
    try:
        report = analyze(args.file, args.pattern, args.strings_limit)
        encoded = json.dumps(report, indent=2, ensure_ascii=False) + "\n"
        if args.output:
            args.output.write_text(encoded, encoding="utf-8")
        else:
            sys.stdout.write(encoded)
    except (OSError, ValueError) as exc:
        print(f"flak1-analyze: {exc}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
